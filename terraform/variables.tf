variable subscription_id {
  type = string
}

variable default_name {
  type = string
}

variable release_name {
  type = string
}

variable default_tags {
  type = map(string)
  default = {}
}

variable metadata_location {
  type = string
  description = "Location of the resource groups and other metadata items."
}

variable resource_location {
  type = string
  description = "Location of other resource items."
}

variable root_ca_certs {
  type = string
}

variable platform_subscription_id {
  type = string
  description = "Subscription ID of the Platform."
}

variable platform_name {
  type = string
}

variable platform_dns_zone_name {
  type = string
}

variable platform_internal_dns_zone_name {
  type = string
}

variable dns_zone_name {
  type = string
  validation {
    condition = endswith(var.dns_zone_name, ".${var.platform_dns_zone_name}")
    error_message = "dns_zone_name must be a subzone of platform_dns_zone_name"
  }
}

variable acme_server {
  type = string
}

variable acme_email {
  type = string
}

variable internal_dns_zone_name {
  type = string
  validation {
    condition = endswith(var.internal_dns_zone_name, ".${var.platform_internal_dns_zone_name}")
    error_message = "internal_dns_zone_name must be a subzone of platform_internal_dns_zone_name"
  }
}

variable internal_acme_server {
  type = string
}

variable internal_acme_email {
  type = string
}

variable aks_vnet_subnet_address_prefixes {
  type = list(string)
}

variable aks_sku_name {
  type = string
  default = "Base"
}

variable aks_sku_tier {
  type = string
  default = "Free"
}

variable aks_availability_zones {
  type = list(number)
  default = []
}

variable aks_aad_admin_group_object_ids {
  type = list(string)
}

variable aks_service_cidr {
  type = string
}

variable aks_dns_service_ip {
  type = string
}

variable aks_pod_cidr {
  type = string
}

variable aks_sys_node_size {
  type = string 
}

variable aks_sys_node_count {
  type = number
  default = 1
}

variable aks_sys_node_min_count {
  type = number
  default = 1
}

variable aks_sys_node_max_count {
  type = number
  default = 3
}
