# general use storage account for the appdev environment
resource azurerm_storage_account environment {
  name = replace(var.default_name, "-", "")
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.environment.name
  location = var.resource_location
  account_tier = "Standard"
  account_kind = "StorageV2"
  account_replication_type = "LRS"
  public_network_access_enabled = true

  network_rules {
    bypass = [ "AzureServices" ]
    default_action = "Deny"
  }

  lifecycle {
    ignore_changes = [ tags ]
    prevent_destroy = true
  }
}

locals {
  storage_subresources = {
    "blob" = "privatelink.blob.core.windows.net",
    "file" = "privatelink.file.core.windows.net",
  }
}

resource azurerm_role_assignment identity_storage_account_contributor {
  role_definition_name = "Storage File Data Privileged Contributor"
  scope = azurerm_storage_account.environment.id
  principal_id = azurerm_user_assigned_identity.environment.principal_id
}

# expose each service of the general use storage account to the private VNet
resource azurerm_private_endpoint storage_account {
  for_each = local.storage_subresources

  name = "${azurerm_storage_account.environment.name}-${each.key}-2-${data.azurerm_virtual_network.platform.name}"
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.environment.name
  location = data.azurerm_virtual_network.platform.location
  subnet_id = data.azurerm_subnet.private.id

  private_service_connection {
    name = "${azurerm_storage_account.environment.name}-${each.key}-2-${data.azurerm_virtual_network.platform.name}"
    private_connection_resource_id = azurerm_storage_account.environment.id
    subresource_names = [each.key]
    is_manual_connection = false
  }

  lifecycle {
    ignore_changes = [tags, private_dns_zone_group]
  }
}
