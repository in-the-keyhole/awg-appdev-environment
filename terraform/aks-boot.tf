locals {
  aks_boot_vars = {
    mark = 9
    hash = filesha1("${path.module}/aks-boot.yaml.tftpl")
    namespace = "awg-appdev"
    default_name = var.default_name
    release_name = var.release_name
    default_tags = var.default_tags
    platform_registry = data.azurerm_container_registry.platform
    awg_appdev_version = "0.0.431"
    azure_subscription_id = data.azurerm_client_config.current.subscription_id
    dns_zone_name = azurerm_dns_zone.public.name
    root_ca_certs = var.root_ca_certs
    acme_server = var.acme_server
    acme_email = var.acme_email
    internal_dns_zone_name = azurerm_private_dns_zone.internal.name
    internal_acme_server = var.internal_acme_server
    internal_acme_email = var.internal_acme_email
    crossplane_azure_identity = azurerm_user_assigned_identity.crossplane
    crossplane_azure_provider_version = "v1"
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
    ]
    env = {
      defaultName = var.default_name
      releaseName = var.release_name
      defaultTags = var.default_tags
      dnsZoneName = azurerm_dns_zone.public.name
      internalDnsZoneName = azurerm_private_dns_zone.internal.name
      azure = {
        tenantId = data.azurerm_client_config.current.tenant_id
        subscriptionId = data.azurerm_client_config.current.subscription_id
        resourceGroupId = azurerm_resource_group.aks.id
        vnetId = data.azurerm_virtual_network.platform.id
        defaultSubnetId = data.azurerm_subnet.default.id
        privateSubnetId = data.azurerm_subnet.private.id
      }
      cluster = azurerm_kubernetes_cluster.aks
    }
  }
  
  aks_boot_zip_content = templatefile("${path.module}/aks-boot.yaml.tftpl", merge(local.aks_boot_vars, {
    uid = sha1(jsonencode(local.aks_boot_vars))
  }))
}

# output aks_boot_zip_content {
#   value = nonsensitive(local.aks_boot_zip_content)
# }

# package required files up into ZIP
data archive_file aks_boot_zip {
  type = "zip"
  output_path = "${path.module}/.terraform/tmp/aks-boot-${md5(local.aks_boot_zip_content)}.zip"
  
  source {
    filename = "aks-boot.yaml"
    content = local.aks_boot_zip_content
  }
}

# use AKS runCommand resource to invoke kubectl, running our init yaml
resource azapi_resource_action aks_boot {
  type = "Microsoft.ContainerService/managedClusters@2025-01-01"
  resource_id = azurerm_kubernetes_cluster.aks.id
  action = "runCommand"
  method = "POST"
  body = {
    clusterToken = data.external.aks_credentials.result.accessToken
    context = filebase64(data.archive_file.aks_boot_zip.output_path)
    command = "kubectl apply -f aks-boot.yaml"
  }
  
  lifecycle {
    replace_triggered_by = [
      
    ]
  }

  depends_on = [
    azapi_resource_action.aks_crossplane_install,
    time_sleep.aks_crossplane_done
  ]
}
