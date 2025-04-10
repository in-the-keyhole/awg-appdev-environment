variable "subscription_id" {
  type = string
}

variable "default_name" {
  type = string
  default = "awg-app"
}

variable "release_name" {
  type = string
  default = "1.0.0"
}

variable "default_tags" {
  type = map(string)
  default = {}
}

variable "metadata_location" {
  type = string
  default = "west us"
  description = "Location of the resource groups and other metadata items."
}

variable "resource_location" {
  type = string
  default = "east us"
  description = "Location of other resource items."
}

variable "vnet_address_prefixes" {
  type = list(string)
  default = ["10.224.0.0/16"]
}

variable "default_vnet_subnet_address_prefixes" {
  type = list(string)
  default = ["10.224.0.0/24"]
}

variable "dns_zone_name" {
  type = string
  default = "app.pub.az.awg.ikvm.org"
}

variable "int_dns_zone_name" {
  type = string
  default = "app.int.az.awg.keyholesoftware.com"
}

variable "aks_sku_name" {
  type = string
  default = "Base"
}

variable "aks_sku_tier" {
  type = string
  default = "Free"
}

variable "aks_availability_zones" {
  type = list(number)
  default = []
}

variable "aks_aad_admin_group_object_ids" {
  type = list(string)
  default = ["d93d0231-bf38-4a92-b3da-124bfef36665"]
}

variable "aks_vnet_subnet_address_prefixes" {
  type = list(string)
  default = ["10.224.1.0/24"]
}

variable "aks_service_cidr" {
  type = string
  default = "192.168.0.0/16"
}

variable "aks_dns_service_ip" {
  type = string
  default = "192.168.0.10"
}

variable "aks_pod_cidr" {
  type = string
  default = "172.16.0.0/12"
}

variable "aks_sys_node_size" {
  type = string 
  default = "Standard_B4ms"
}

variable "aks_sys_node_count" {
  type = number
  default = 1
}

variable "aks_sys_node_min_count" {
  type = number
  default = 1
}

variable "aks_sys_node_max_count" {
  type = number
  default = 3
}
