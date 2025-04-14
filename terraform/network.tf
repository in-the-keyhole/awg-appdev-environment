data azurerm_virtual_network platform {
  provider = azurerm.platform
  name = var.platform_name
  resource_group_name = data.azurerm_resource_group.platform.name
}

