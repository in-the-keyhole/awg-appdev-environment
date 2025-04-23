data azurerm_virtual_network platform {
  provider = azurerm.platform
  name = var.platform_name
  resource_group_name = data.azurerm_resource_group.platform.name
}

data azurerm_subnet private {
  provider = azurerm.platform
  name = "private"
  resource_group_name = data.azurerm_resource_group.platform.name
  virtual_network_name = data.azurerm_virtual_network.platform.name
}

data azurerm_subnet aci {
  provider = azurerm.platform
  name = "aci"
  resource_group_name = data.azurerm_resource_group.platform.name
  virtual_network_name = data.azurerm_virtual_network.platform.name
}