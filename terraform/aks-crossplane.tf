# prepare initial identity for bootstrapping Crossplane
resource azurerm_user_assigned_identity crossplane {
  name = "${var.default_name}-crossplane"
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = var.resource_location

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# assign Crossplane as Resource Group Contributor to the subscription so it can create new resource groups
# TODO change this from Owner
resource azurerm_role_assignment crossplane_rg_contributor {
  role_definition_name = "Owner"
  scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  principal_id = azurerm_user_assigned_identity.crossplane.principal_id
}

# associate Crossplane identity with Azure Provider
resource azurerm_federated_identity_credential crossplane_azure {
  name = "crossplane-system_upbound-provider-azure"
  resource_group_name = azurerm_resource_group.aks.name
  audience = ["api://AzureADTokenExchange"]
  issuer = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.crossplane.id
  subject = "system:serviceaccount:crossplane-system:upbound-provider-azure"
}

# associate Crossplane identity with Helm Provider
resource azurerm_federated_identity_credential crossplane_helm {
  name = "crossplane-system_upbound-provider-helm"
  resource_group_name = azurerm_resource_group.aks.name
  audience = ["api://AzureADTokenExchange"]
  issuer = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.crossplane.id
  subject = "system:serviceaccount:crossplane-system:upbound-provider-helm"
}


# wait for AKS to come up
resource time_sleep aks_wait {
  depends_on = [azurerm_kubernetes_cluster.aks]
  create_duration = "30s"
}

# use AKS runCommand to install Crossplane
resource azapi_resource_action aks_crossplane_install {
  type = "Microsoft.ContainerService/managedClusters@2025-01-01"
  resource_id = azurerm_kubernetes_cluster.aks.id
  action = "runCommand"
  method = "POST"
  body = {
    clusterToken = data.external.aks_credentials.result.accessToken
    command = "helm repo add crossplane-stable https://charts.crossplane.io/stable && helm repo update && helm upgrade --install crossplane --namespace crossplane-system --create-namespace --wait crossplane-stable/crossplane --version 1.19.0 --set args={'--debug'}"
  }

  depends_on = [
    time_sleep.aks_wait
  ]
}

# wait for AKS to come up
resource time_sleep aks_crossplane_done {
  depends_on = [azapi_resource_action.aks_crossplane_install]
  create_duration = "30s"
}