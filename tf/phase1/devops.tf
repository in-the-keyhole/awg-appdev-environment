resource "azurerm_resource_group" "devops" {
  name = "${var.default_name}-devops"
  tags = var.default_tags
  location = var.metadata_location
}

resource "azurerm_storage_account" "devops" {
  name = replace("${var.default_name}-devops", "-", "")
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.devops.name
  location = var.resource_location
  account_tier = "Standard"
  account_kind = "StorageV2"
  account_replication_type = "LRS"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "devops" {
  name = "${var.default_name}-devops"
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.devops.name
  location = var.resource_location
  sku_name = "standard"
  tenant_id = data.azurerm_client_config.current.tenant_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_container_registry" "devops" {
  name = replace("${var.default_name}-devops", "-", "")
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.devops.name
  location = var.resource_location
  sku = "Basic"
  admin_enabled = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "aks_2_acr" {
  scope = azurerm_container_registry.devops.id
  role_definition_name = "AcrPull"
  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
