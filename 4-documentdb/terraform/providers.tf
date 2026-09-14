terraform {
  required_version = "= 1.13.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.5"
    }
  }

}

provider "azurerm" {
  features {
    storage {
      data_plane_available = false
    }
  }

  storage_use_azuread             = true
  subscription_id                 = var.SUBSCRIPTION_ID
  resource_provider_registrations = "core"

  resource_providers_to_register = [
    "Microsoft.App"
  ]
}

provider "azapi" {}
