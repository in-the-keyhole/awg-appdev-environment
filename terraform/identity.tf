resource azurerm_user_assigned_identity environment {
  name = var.default_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.environment.name
  location = var.resource_location

  lifecycle {
    ignore_changes = [ tags ]
  }
}

resource azurerm_role_assignment contributor {
  role_definition_name = "Contributor"
  scope = azurerm_resource_group.environment.id
  principal_id = azurerm_user_assigned_identity.environment.principal_id
}
