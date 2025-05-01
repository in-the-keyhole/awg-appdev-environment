# data collection endpoint for Managed Prometheus
resource azurerm_monitor_data_collection_endpoint prometheus {
  name = substr("MSProm-${data.azurerm_monitor_workspace.platform.location}-${azurerm_kubernetes_cluster.aks.name}", 0, min(44, length("MSProm-${data.azurerm_monitor_workspace.platform.location}-${azurerm_kubernetes_cluster.aks.name}")))
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = data.azurerm_monitor_workspace.platform.location
  kind = "Linux"
  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [ tags ]
  }
}

resource azurerm_monitor_private_link_scoped_service prometheus {
  name = substr("MSProm-${data.azurerm_monitor_workspace.platform.location}-${azurerm_kubernetes_cluster.aks.name}", 0, min(44, length("MSProm-${data.azurerm_monitor_workspace.platform.location}-${azurerm_kubernetes_cluster.aks.name}")))
  resource_group_name = data.azurerm_monitor_workspace.platform.resource_group_name
  scope_name = data.azurerm_monitor_workspace.platform.name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.prometheus.id
}

resource azurerm_monitor_data_collection_rule prometheus {
  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  name = substr("MSProm-${azurerm_monitor_data_collection_endpoint.prometheus.location}-${azurerm_kubernetes_cluster.aks.name}", 0, min(44, length("MSProm-${azurerm_monitor_data_collection_endpoint.prometheus.location}-${azurerm_kubernetes_cluster.aks.name}")))
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = azurerm_monitor_data_collection_endpoint.prometheus.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
  kind = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = data.azurerm_monitor_workspace.platform.id
      name = "MonitoringAccount1"
    }
  }

  data_flow {
    streams = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name = "PrometheusDataSource"
    }
  }

  lifecycle {
    ignore_changes = [ tags ]
  }
}

resource azurerm_monitor_data_collection_rule_association prometheus_dcra_rule {
  name = "MSProm-${azurerm_kubernetes_cluster.aks.location}-${azurerm_kubernetes_cluster.aks.name}"
  description = "Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster."
  target_resource_id = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus.id
}

resource azurerm_monitor_data_collection_rule_association prometheus_dcra_endpoint {
  name = "configurationAccessEndpoint"
  description = "Association of data collection endpoint. Deleting this association will break the data collection for this AKS Cluster."
  target_resource_id = azurerm_kubernetes_cluster.aks.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus.id
}
