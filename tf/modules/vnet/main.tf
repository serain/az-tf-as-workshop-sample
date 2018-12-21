resource "azurerm_resource_group" "rg" {
  name                = "storeit"
  location            = "uksouth"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = "uksouth"
  address_space       = ["10.1.0.0/16"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
}
