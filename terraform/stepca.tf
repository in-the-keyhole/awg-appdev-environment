# We use a deployment script here to retrieve the roots.pem file from StepCA. We do this so we can retrieve it from a
# machine inside the network. The ACI instance underlying the script runs on the 'aci' subnet. This data goes to the
# AKS cluster in two ways: first, as trusted CA certificates (Azure-level), and second as an argument to 
# `awg-appdev-init` which injects a trust-manager bundle.
resource azapi_resource roots_pem {
  type = "Microsoft.Resources/deploymentScripts@2023-08-01"
  name = "${var.default_name}-roots-pem"
  parent_id = azurerm_resource_group.environment.id
  location = var.resource_location

  body = {
    kind = "AzureCLI"

    properties = {
      azCliVersion = "2.69.0"
      retentionInterval = "P1D"
      cleanupPreference = "OnSuccess"
      forceUpdateTag = timestamp()

      storageAccountSettings = {
        storageAccountName = azurerm_storage_account.environment.name
      }

      containerSettings = {
        subnetIds = [{
          id = data.azurerm_subnet.aci.id
        }]
      }

      scriptContent = <<-EOF
        set -e
        jq -Rs '{"roots_pem":.}' <(curl -kvs "https://ca.${data.azurerm_private_dns_zone.platform_internal.name}/roots.pem") > $AZ_SCRIPTS_OUTPUT_PATH
      EOF
    }
  }

  response_export_values = [
    "*", 
  ]

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.environment.id
    ]
  }
}

locals {
  roots_pem = azapi_resource.roots_pem.output.properties.outputs.roots_pem
}
