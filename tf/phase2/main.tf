# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "~>4.0"
#     }
#     azapi = {
#       source  = "azure/azapi"
#       version = "~>2.3"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~>2.36"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~>2.0"
#     }
#     local = {
#       source = "hashicorp/local"
#       version = "~>2.5"
#     }
#   }
# }

# data "azurerm_client_config" "current" {

# }

# data "azurerm_resource_group" "aks" {
#   name = "${var.default_name}-aks"
# }

# data "azurerm_kubernetes_cluster" "aks" {
#   name = var.default_name
#   resource_group_name = "${var.default_name}-aks"
# }
