# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


##################################################
# RESOURCES                                      #
##################################################
# -
# - Create Mongo DB
# -
resource "azurerm_cosmosdb_mongo_database" "this" {
  name                = var.db_name
  resource_group_name = data.azurerm_resource_group.this.name
  account_name        = data.azurerm_cosmosdb_account.this.name
  throughput          = var.db_max_throughput != null ? null : var.db_throughput

  # Autoscaling is optional and depends on max throughput parameter. Mutually exclusive vs. throughput. 
  dynamic "autoscale_settings" {
    for_each = var.db_max_throughput != null ? [1] : []
    content {
      max_throughput = var.db_max_throughput
    }
  }
}

# -
# - Create Mongo Collection
# -
resource "azurerm_cosmosdb_mongo_collection" "this" {
  name                   = each.value.collection_name
  resource_group_name    = data.azurerm_resource_group.this.name
  account_name           = data.azurerm_cosmosdb_account.this.name
  database_name          = each.value.db_name
  default_ttl_seconds    = each.value.default_ttl_seconds != null ? each.value.default_ttl_seconds : null
  shard_key              = each.value.shard_key
  throughput             = each.value.collection_max_throughput != null ? null : each.value.collection_throughout
  analytical_storage_ttl = each.value.analytical_storage_ttl != null ? each.value.analytical_storage_ttl : null

  # Autoscaling is optional and depends on max throughput parameter. Mutually exclusive vs. throughput. 
  dynamic "autoscale_settings" {
    for_each = each.value.collection_max_throughput != null ? [1] : []
    content {
      max_throughput = each.value.collection_max_throughput
    }
  }

  # Index is optional
  dynamic "index" {
    for_each = each.value.indexes != null ? each.value.indexes : {}
    content {
      keys   = index.value.mongo_index_keys
      unique = index.value.mongo_index_unique != null ? index.value.mongo_index_unique : null
    }
  }
  # Depends on existence of Cosmos DB SQL API Database managed by module
  depends_on = [
    azurerm_cosmosdb_mongo_database.this
  ]
}