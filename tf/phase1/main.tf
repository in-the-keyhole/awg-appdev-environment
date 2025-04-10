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
    local = {
      source = "hashicorp/local"
      version = "~>2.5"
    }
  }
}

data "azurerm_client_config" "current" {

}
