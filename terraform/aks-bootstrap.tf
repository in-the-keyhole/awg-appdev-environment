# get access token to AKS instance
# TODO this isn't quite right since it doesn't adopt azurerm's authentication information
data external aks_credentials {
  program = [ "az", "account", "get-access-token", "--resource", "6dae42f8-4368-4678-94ff-3960e28e3630", "-o", "json", "--query", "{accessToken: accessToken}" ]
}

locals {
  aks_bootstrap_vars = {
    mark = 6
    hash = filesha1("${path.module}/aks-bootstrap.yaml.tftpl")
    namespace = "awg-appdev"
    default_name = var.default_name
    release_name = var.release_name
    default_tags = var.default_tags
    platform_registry = data.azurerm_container_registry.platform
    awg_appdev_version = "0.0.233"
    azure_subscription_id = data.azurerm_client_config.current.subscription_id,
    crossplane_azure_identity = azurerm_user_assigned_identity.crossplane
    crossplane_azure_provider_version = "v1.11.3"
    crossplane_azure_provider_package = [
      "authorization",
      "compute",
      "cosmosdb",
      "dbformysql",
      "dbforpostgresql",
      "eventgrid",
      "insights",
      "keyvault",
      "logic",
      "managedidentity",
      "network",
      "resources",
      "servicebus",
      "signalrservice",
      "sql",
      "storage",
      "web"
    ],
    env = {
      defaultName = var.default_name
      releaseName = var.release_name
      defaultTags = var.default_tags
      dnsZoneName = azurerm_dns_zone.public.name,
      internalDnsZoneName = azurerm_private_dns_zone.internal.name,
      azure = {
        tenantId = data.azurerm_client_config.current.tenant_id,
        subscriptionId = data.azurerm_client_config.current.subscription_id,
        resourceGroupId = azurerm_resource_group.aks.id,
        vnetId = data.azurerm_virtual_network.platform.id
      }
      cluster = azurerm_kubernetes_cluster.aks
    }
  }
}

# package required files up into ZIP
data archive_file aks_bootstrap_zip {
  type = "zip"
  output_path = "${path.module}/.terraform/tmp/aks-boot.zip"
  
  source {
    filename = "aks-bootstrap.yaml"
    content = templatefile("${path.module}/aks-bootstrap.yaml.tftpl", merge(local.aks_bootstrap_vars, {
      uid = sha1(jsonencode(local.aks_bootstrap_vars))
    }))
  }
}

# wait for AKS to come up
resource time_sleep aks_wait {
  depends_on = [azurerm_kubernetes_cluster.aks]
  create_duration = "30s"
}

# use AKS runCommand to install Crossplane
resource azapi_resource_action aks_install_crossplane {
  type = "Microsoft.ContainerService/managedClusters@2025-01-01"
  resource_id = azurerm_kubernetes_cluster.aks.id
  action = "runCommand"
  method = "POST"
  body = {
    clusterToken = data.external.aks_credentials.result.accessToken
    command = "helm repo add crossplane-stable https://charts.crossplane.io/stable && helm repo update && helm upgrade --install crossplane --namespace crossplane-system --create-namespace --wait crossplane-stable/crossplane --version 1.19.0 --set args={'--debug'}"
  }

  depends_on = [
    time_sleep.aks_wait
  ]
}

# wait for AKS to come up
resource time_sleep aks_wait_2 {
  depends_on = [azapi_resource_action.aks_install_crossplane]
  create_duration = "30s"
}

# use AKS runCommand resource to invoke kubectl, running our init yaml
resource azapi_resource_action aks_bootstrap {
  type = "Microsoft.ContainerService/managedClusters@2025-01-01"
  resource_id = azurerm_kubernetes_cluster.aks.id
  action = "runCommand"
  method = "POST"
  body = {
    clusterToken = data.external.aks_credentials.result.accessToken
    context = filebase64(data.archive_file.aks_bootstrap_zip.output_path)
    command = "kubectl apply -f aks-bootstrap.yaml"
  }

  depends_on = [
    time_sleep.aks_wait_2,
    azapi_resource_action.aks_install_crossplane
  ]
}
