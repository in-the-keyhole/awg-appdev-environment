# create the AKS subnet in the platform VNet
resource azurerm_subnet aks {
  provider = azurerm.platform
  name = "${var.default_name}-aks"
  resource_group_name = data.azurerm_resource_group.platform.name
  virtual_network_name = data.azurerm_virtual_network.platform.name
  address_prefixes = var.aks_vnet_subnet_address_prefixes
}

# assign permissions to the subnet for the AKS identity
resource azurerm_role_assignment aks_network_contributor {
  role_definition_name = "Network Contributor"
  scope = azurerm_subnet.aks.id
  principal_id = azurerm_user_assigned_identity.aks.principal_id
}

# create the AKS resource group
resource azurerm_resource_group aks {
  name = "rg-${var.default_name}-aks"
  tags = var.default_tags
  location = var.metadata_location

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# create the AKS network security group
resource azurerm_network_security_group aks {
  name = "${var.default_name}-aks"
  resource_group_name = azurerm_resource_group.aks.name
  location = data.azurerm_virtual_network.platform.location

  security_rule {
    name = "AllowAllInBound"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# associate the NSG with the subnet
resource azurerm_subnet_network_security_group_association aks {
  provider = azurerm.platform
  subnet_id = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# public key resource to hold AKS SSH key
resource azapi_resource ssh_public_key {
  type = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name = "${var.default_name}-aks"
  tags = var.default_tags
  location  = var.resource_location
  parent_id = azurerm_resource_group.aks.id

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# generate a SSH key for the AKS cluster
resource azapi_resource_action ssh_public_key {
  type = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action = "generateKeyPair"
  method = "POST"
  response_export_values = ["publicKey", "privateKey"]
}

# prepare identity for AKS
resource azurerm_user_assigned_identity aks {
  name = "${var.default_name}-aks"
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = var.resource_location

  lifecycle {
    ignore_changes = [ tags ]
  }
}

# assign ourselves as RBAC Cluster Admin to the AKS resource group
resource azurerm_role_assignment aks_cluster_admin {
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope = azurerm_resource_group.aks.id
  principal_id = data.azurerm_client_config.current.object_id
}

# assign ourselves as Private DNS Zone Contributor to the AKS private zone
resource azurerm_role_assignment aks_dns_contributor {
  provider = azurerm.platform
  role_definition_name = "Private DNS Zone Contributor"
  scope = "${data.azurerm_resource_group.platform.id}/providers/Microsoft.Network/privateDnsZones/${var.platform_name}.privatelink.${var.resource_location}.azmk8s.io"
  principal_id = azurerm_user_assigned_identity.aks.principal_id
}

# deploy AKS cluster for the environment
resource azurerm_kubernetes_cluster aks {
  name = var.default_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = var.resource_location

  sku_tier = "Standard"
  kubernetes_version = "1.32"
  private_cluster_enabled = true
  private_dns_zone_id = "${data.azurerm_resource_group.platform.id}/providers/Microsoft.Network/privateDnsZones/${var.platform_name}.privatelink.${var.resource_location}.azmk8s.io"
  private_cluster_public_fqdn_enabled = false
  
  dns_prefix = var.default_name
  node_resource_group = "${azurerm_resource_group.aks.name}-mc"
  local_account_disabled = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled = true
  workload_identity_enabled = true
  automatic_upgrade_channel = "stable"
  node_os_upgrade_channel = "NodeImage"

  image_cleaner_enabled = true
  image_cleaner_interval_hours = 7 * 24

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.aks.id
    ]
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    admin_group_object_ids = var.aks_aad_admin_group_object_ids
  }

  network_profile {
    network_plugin = "azure"
    network_plugin_mode = "overlay"
    network_policy = "cilium"
    network_data_plane = "cilium"
    dns_service_ip = var.aks_dns_service_ip
    service_cidr = var.aks_service_cidr
    pod_cidr = var.aks_pod_cidr
    outbound_type = "loadBalancer"
    load_balancer_sku = "standard"
  }

  service_mesh_profile {
    mode = "Istio"
    revisions = ["asm-1-24"]
    internal_ingress_gateway_enabled = true
    external_ingress_gateway_enabled = true
  }

  monitor_metrics {
    annotations_allowed = true
    labels_allowed = true
  }

  workload_autoscaler_profile {
    keda_enabled = true
    vertical_pod_autoscaler_enabled = true
  }

  linux_profile {
    admin_username = "sysadmin"
    ssh_key {
      key_data = azapi_resource_action.ssh_public_key.output.publicKey
    }
  }

  default_node_pool {
    name = "sys0"
    temporary_name_for_rotation = "sys0tmp"
    tags = var.default_tags

    vm_size = var.aks_sys_node_size
    os_sku = "AzureLinux"
    os_disk_size_gb = 64

    vnet_subnet_id = azurerm_subnet.aks.id
    zones = var.aks_availability_zones

    auto_scaling_enabled = true
    min_count = var.aks_sys_node_min_count
    max_count = var.aks_sys_node_max_count

    upgrade_settings {
      drain_timeout_in_minutes = 0
      max_surge = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  maintenance_window_node_os {
    frequency = "Weekly"
    interval = 1
    duration = 4
    day_of_week = "Sunday"
    utc_offset = "-06:00"
    start_time = "00:00"
  }

  lifecycle {
    ignore_changes = [ tags ]
    prevent_destroy = true
  }

  depends_on = [
    azurerm_role_assignment.aks_cluster_admin,
    azurerm_role_assignment.aks_dns_contributor 
  ]
}

# Update the custom CA trust certificates property in AKS. We must do this by hand since Terraform does not support it.
resource azapi_update_resource aks_internal_ca {
  type = "Microsoft.ContainerService/managedClusters@2025-01-01"
  resource_id = azurerm_kubernetes_cluster.aks.id

  body = {
    properties ={
      securityProfile = {
        customCaTrustCertificates = [ base64encode(var.root_ca_certs)]
      }
    }
  }
}

# get access token to AKS instance
# TODO this isn't quite right since it doesn't adopt azurerm's authentication information
data external aks_credentials {
  program = [ "az", "account", "get-access-token", "--resource", "6dae42f8-4368-4678-94ff-3960e28e3630", "-o", "json", "--query", "{accessToken: accessToken}" ]
}
