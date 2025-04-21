data azurerm_container_registry platform {
  provider = azurerm.platform
  name = replace("${var.platform_name}", "-", "")
  resource_group_name = data.azurerm_resource_group.platform.name
}

resource "azurerm_role_assignment" "aks_2_acr" {
  provider = azurerm.platform
  role_definition_name = "AcrPull"
  scope = data.azurerm_container_registry.platform.id
  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
