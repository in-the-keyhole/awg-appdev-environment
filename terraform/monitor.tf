data azurerm_monitor_workspace platform {
  provider = azurerm.platform
  name = var.platform_name
  resource_group_name = data.azurerm_resource_group.platform.name
}
