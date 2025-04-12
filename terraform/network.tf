data azurerm_dns_zone platform {
  provider = azurerm.platform
  name = var.platform_dns_zone_name
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource azurerm_dns_zone public {
  name = var.dns_zone_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.environment.name

  lifecycle {
    ignore_changes = [ tags ]
  }
}

resource azurerm_dns_ns_record public_delegation {
  provider = azurerm.platform
  name = substr(var.dns_zone_name, 0, length(var.dns_zone_name) - length(data.azurerm_dns_zone.platform.name) - 1)
  tags = var.default_tags
  resource_group_name = data.azurerm_dns_zone.platform.resource_group_name
  zone_name = data.azurerm_dns_zone.platform.name
  records = tolist(azurerm_dns_zone.public.name_servers)
  ttl = 300

  lifecycle {
    ignore_changes = [ tags ]
  }
}

data azurerm_private_dns_zone platform_internal {
  provider = azurerm.platform
  name = var.platform_internal_dns_zone_name
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource azurerm_private_dns_zone internal {
  name = var.internal_dns_zone_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.environment.name

  lifecycle {
    ignore_changes = [ tags ]
  }
}

resource azurerm_private_dns_zone_virtual_network_link internal {
  name = "${azurerm_private_dns_zone.internal.name}-2-${data.azurerm_virtual_network.platform.name}"
  tags = var.default_tags
  resource_group_name = azurerm_private_dns_zone.internal.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id = data.azurerm_virtual_network.platform.id

  lifecycle {
    ignore_changes = [ tags ]
  }
  
  depends_on = [ 
    azurerm_private_dns_zone.internal
  ]
}

data azurerm_virtual_network platform {
  provider = azurerm.platform
  name = var.platform_name
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource azurerm_subnet aks {
  provider = azurerm.platform
  name = "${var.default_name}-aks"
  resource_group_name = data.azurerm_resource_group.platform.name
  virtual_network_name = data.azurerm_virtual_network.platform.name
  address_prefixes = var.aks_vnet_subnet_address_prefixes
}

resource azurerm_network_security_group aks {
  name = "${var.default_name}-aks"
  resource_group_name = azurerm_resource_group.aks.name
  location = data.azurerm_virtual_network.platform.location

  security_rule {
    name = "SSH"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  lifecycle {
    ignore_changes = [ tags ]
  }
}
