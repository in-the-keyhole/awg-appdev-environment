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
  }
  backend azurerm {
    
  }
}

provider azurerm {
  subscription_id = var.subscription_id
  features {}
}

provider azapi {
  subscription_id = var.subscription_id
}

provider azurerm {
  alias = "platform"
  subscription_id = var.platform_subscription_id
  features {}
}

data azurerm_client_config current {

}

data azurerm_client_config platform {
  provider = azurerm.platform
}

data azurerm_resource_group platform {
  provider = azurerm.platform
  name = "rg-${var.platform_name}"
}

resource azurerm_resource_group environment {
  name = "rg-${var.default_name}"
  tags = var.default_tags
  location = var.metadata_location

  lifecycle {
    ignore_changes = [ tags ]
    prevent_destroy = true
  }
}
