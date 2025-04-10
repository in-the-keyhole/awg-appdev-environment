resource "azurerm_resource_group" "aks" {
  name = "${var.default_name}-aks"
  tags = var.default_tags
  location = var.metadata_location
}

resource "azapi_resource" "ssh_public_key" {
  type = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name = "${var.default_name}-aks"
  location  = var.resource_location
  parent_id = azurerm_resource_group.aks.id
}

resource "azapi_resource_action" "ssh_public_key" {
  type = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action = "generateKeyPair"
  method = "POST"
  response_export_values = ["publicKey", "privateKey"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name = var.default_name
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = var.resource_location

  kubernetes_version = "1.32.3"
  dns_prefix = "${var.default_name}"
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
    type = "SystemAssigned"
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
    revisions = ["asm-1-23"]
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
    prevent_destroy = false
  }
}

resource "azurerm_role_assignment" "aksclusteradmin" {
  scope = azurerm_resource_group.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id = data.azurerm_client_config.current.object_id
}

# prepare initial identity for bootstrapping Crossplane
resource azurerm_user_assigned_identity "crossplane" {
  name = "${var.default_name}-crossplane"
  tags = var.default_tags
  resource_group_name = azurerm_resource_group.aks.name
  location = var.resource_location
}

# associate Crossplane identity with eventual ServiceAccount
resource azurerm_federated_identity_credential "crossplane-azure" {
  name = "aks"
  resource_group_name = azurerm_resource_group.aks.name
  audience = ["api://AzureADTokenExchange"]
  issuer = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id = azurerm_user_assigned_identity.crossplane.id
  subject = "system:serviceaccount:crossplane-system:azure"
}