resource "azurerm_subnet" "sub" {
  name                 = "back"
  resource_group_name  = "${var.rg}"
  virtual_network_name = "vnet"
  address_prefix       = "10.1.2.0/24"
}

resource "azurerm_network_security_group" "nsg" {
  name                               = "back-nsg"
  location                           = "uksouth"
  resource_group_name                = "${var.rg}"

  # http from internet
  security_rule {
    name                             = "http-inbound"
    priority                         = 100
    direction                        = "inbound"
    access                           = "allow"
    protocol                         = "tcp"
    source_port_range                = "*"
    destination_port_range           = "3000"
    source_address_prefix            = "10.1.1.0/24"
    destination_address_prefix       = "*"
  }

  # ssh from mgmt
  security_rule {
    name                             = "ssh-inbound"
    priority                         = 110
    direction                        = "inbound"
    access                           = "allow"
    protocol                         = "tcp"
    source_port_range                = "*"
    destination_port_range           = "22"
    source_address_prefix            = "10.1.10.0/24"
    destination_address_prefix       = "*"
  }
 
  security_rule {
    name                             = "deny-vnet-inbound"
    priority                         = 4096
    direction                        = "inbound"
    access                           = "deny"
    protocol                         = "*"
    source_port_range                = "*"
    destination_port_range           = "*"
    source_address_prefix            = "VirtualNetwork"
    destination_address_prefix       = "*"
  }

  security_rule {
    name                             = "deny-vnet-outbound"
    priority                         = 4096
    direction                        = "outbound"
    access                           = "deny"
    protocol                         = "*"
    source_port_range                = "*"
    destination_port_range           = "*"
    source_address_prefix            = "*"
    destination_address_prefix       = "VirtualNetwork"
  }
} 

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = "${azurerm_subnet.sub.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

resource "azurerm_network_interface" "nic" {
  name                               = "app-nic"
  location                           = "uksouth"
  resource_group_name                = "${var.rg}"

  ip_configuration {
    name                             = "app-ip"
    subnet_id                        = "${azurerm_subnet.sub.id}"
    private_ip_address_allocation    = "dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                               = "app"
  location                           = "uksouth"
  resource_group_name                = "${var.rg}"
  vm_size                            = "Standard_A1_v2"
  network_interface_ids              = [
    "${azurerm_network_interface.nic.id}"
  ]

  delete_os_disk_on_termination      = true
  delete_data_disks_on_termination   = true

  storage_image_reference {
    publisher                        = "Canonical"
    offer                            = "UbuntuServer"
    sku                              = "18.04-LTS"
    version                          = "latest"
  }

  storage_os_disk {
    name                             = "app-dsk"
    caching                          = "ReadWrite"
    create_option                    = "FromImage"
    managed_disk_type                = "Standard_LRS"
  }

  os_profile {
    computer_name                    = "app"
    admin_username                   = "${var.vm_user}"
  }

  os_profile_linux_config {
    disable_password_authentication  = true

    ssh_keys {
      path                           = "/home/${var.vm_user}/.ssh/authorized_keys"
      key_data                       = "${var.vm_ssh_key}"
    }
  }
}

resource "azurerm_cosmosdb_account" "db" {
    name = "storeit-cosmosdb"
    location = "uksouth"
    resource_group_name = "${var.rg}"
    offer_type = "Standard"
    kind = "GlobalDocumentDB"

    enable_automatic_failover = true
    is_virtual_network_filter_enabled = true

    consistency_policy {
        consistency_level = "BoundedStaleness"
        max_interval_in_seconds = 10
        max_staleness_prefix = 200
    }

    geo_location {
        location = "uksouth"
        failover_priority = 0
    }

    virtual_network_rule {
        id = "${azurerm_subnet.sub.id}"
    }
}
