terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>2.3"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.36"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~>2.5"
    }
  }
  backend "azurerm" {
    
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {

}

data "azurerm_kubernetes_cluster" "aks" {
  depends_on = [module.phase1] # refresh cluster state before reading
  name = var.default_name
  resource_group_name = "${var.default_name}-aks"
}

module "phase1" {
  source = "./phase1"
  subscription_id = var.subscription_id
  default_name = var.default_name
  release_name = var.release_name
  default_tags = var.default_tags
  metadata_location = var.metadata_location
  resource_location = var.resource_location
  vnet_address_prefixes = var.vnet_address_prefixes
  default_vnet_subnet_address_prefixes = var.default_vnet_subnet_address_prefixes
  dns_zone_name = var.dns_zone_name
  int_dns_zone_name = var.int_dns_zone_name
  aks_sku_name = var.aks_sku_name
  aks_sku_tier = var.aks_sku_tier
  aks_availability_zones = var.aks_availability_zones
  aks_aad_admin_group_object_ids = var.aks_aad_admin_group_object_ids
  aks_vnet_subnet_address_prefixes = var.aks_vnet_subnet_address_prefixes
  aks_service_cidr = var.aks_service_cidr
  aks_dns_service_ip = var.aks_dns_service_ip
  aks_pod_cidr = var.aks_pod_cidr
  aks_sys_node_size = var.aks_sys_node_size
  aks_sys_node_min_count = var.aks_sys_node_min_count
  aks_sys_node_max_count = var.aks_sys_node_max_count
}
