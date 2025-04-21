locals {
  aks_bootstrap_vars = {
    mark = 6
    hash = filesha1("${path.module}/aks-bootstrap.yaml.tftpl")
    namespace = "awg-appdev"
    default_name = var.default_name
    release_name = var.release_name
    default_tags = var.default_tags
    platform_registry = data.azurerm_container_registry.platform
    awg_appdev_version = "0.0.350"
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
        vnetId = data.azurerm_virtual_network.platform.id,
        privateSubnetId = data.azurerm_subnet.private.id
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
    azapi_resource_action.aks_crossplane_install,
    time_sleep.aks_crossplane_done
  ]
}
