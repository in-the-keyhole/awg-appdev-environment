resource azurerm_resource_provider_registration dashboard {
  name = "Microsoft.Dashboard"
}

resource azurerm_dashboard_grafana grafana {
  name = var.default_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = azurerm_kubernetes_cluster.aks.location
  grafana_major_version = "11"

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = data.azurerm_monitor_workspace.platform.id
  }

  lifecycle {
    ignore_changes = [ tags ]
  }

  depends_on = [ 
    azurerm_resource_provider_registration.dashboard 
  ]
}

resource azurerm_role_assignment datareaderrole {
  scope = data.azurerm_monitor_workspace.platform.id
  role_definition_id = "/subscriptions/${split("/", data.azurerm_monitor_workspace.platform.id)[2]}/providers/Microsoft.Authorization/roleDefinitions/b0d8363b-8ddd-447d-831f-62ca05bff136"
  principal_id = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}
