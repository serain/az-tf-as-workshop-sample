output "cosmosdb-uri" {
    value = "${azurerm_cosmosdb_account.db.endpoint}"
}
