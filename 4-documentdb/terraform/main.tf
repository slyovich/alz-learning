resource "azapi_resource" "mongo_cluster" {
  type      = "Microsoft.DocumentDB/mongoClusters@2025-09-01"
  parent_id = azurerm_resource_group.this.id
  name      = "mongo-${var.PROJECT}-${var.REGION_SHORTNAME}-${var.ENVIRONMENT}-001"
  location  = azurerm_resource_group.this.location
  body = {
    properties = {
      administrator = {
        userName = var.ADMINISTRATOR_LOGIN
        password = var.ADMINISTRATOR_LOGIN_PASSWORD
      }
      authConfig = {
        allowedModes = ["MicrosoftEntraID", "NativeAuth"]
      }
      compute = {
        tier = "M10"
      }
      highAvailability = {
        targetMode = "Disabled"
      }
      serverVersion       = "8.0"
      publicNetworkAccess = "Enabled"
      sharding = {
        shardCount = 1
      }
      storage = {
        sizeGb = 32
      }
    }
  }
  schema_validation_enabled = false
  response_export_values    = ["*"]
}

resource "azapi_resource" "mongo_admin_user_current" {
  type      = "Microsoft.DocumentDB/mongoClusters/users@2025-09-01"
  name      = data.azurerm_client_config.current.object_id
  parent_id = azapi_resource.mongo_cluster.id

  body = {
    properties = {
      roles = [
        {
          role = "root"
          db   = "admin"
        }
      ]
      identityProvider = {
        type = "MicrosoftEntraID"
        properties = {
          principalType = "User"
        }
      }
    }
  }
  schema_validation_enabled = false
  response_export_values    = ["*"]
}
