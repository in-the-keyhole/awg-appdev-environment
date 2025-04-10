resource "azurerm_resource_group" "network" {
  name = "${var.default_name}-network"
  tags = var.default_tags
  location = var.metadata_location
}

resource "azurerm_dns_zone" "pub" {
  name = var.dns_zone_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_private_dns_zone" "int" {
  name = var.int_dns_zone_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_virtual_network" "network" {
  name = "${var.default_name}"
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.network.name
  location = var.resource_location
  address_space = var.vnet_address_prefixes
}

resource "azurerm_subnet" "default" {
  name = "default"
  resource_group_name = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes = var.default_vnet_subnet_address_prefixes
}

resource "azurerm_subnet" "aks" {
  name = "aks"
  resource_group_name = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes = var.aks_vnet_subnet_address_prefixes
}

resource "random_id" "azurerm_private_dns_zone_virtual_network_link_name" {
  byte_length = 8
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet" {
  name = "tf${random_id.azurerm_private_dns_zone_virtual_network_link_name.hex}"
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.int.name
  virtual_network_id = azurerm_virtual_network.network.id
}
