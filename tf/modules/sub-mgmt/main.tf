resource "azurerm_subnet" "sub" {
  name                 = "mgmt"
  resource_group_name  = "${var.rg}"
  virtual_network_name = "vnet"
  address_prefix       = "10.1.10.0/24"
}

resource "azurerm_network_security_group" "nsg" {
  name                               = "mgmt-nsg"
  location                           = "uksouth"
  resource_group_name                = "${var.rg}"

  # ssh from internet
  security_rule {
    name                             = "ssh-inbound"
    priority                         = 100
    direction                        = "inbound"
    access                           = "allow"
    protocol                         = "tcp"
    source_port_range                = "*"
    destination_port_range           = "22"
    source_address_prefix            = "Internet"
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

  # ssh to rest of vnet
  security_rule {
    name                             = "ssh-outbound"
    priority                         = 100
    direction                        = "outbound"
    access                           = "allow"
    protocol                         = "tcp"
    source_port_range                = "*"
    destination_port_range           = "22"
    source_address_prefix            = "*"
    destination_address_prefix       = "VirtualNetwork"
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

resource "azurerm_public_ip" "pip" {
  name                               = "jb-pip"
  location                           = "uksouth"
  resource_group_name                = "${var.rg}"
  public_ip_address_allocation       = "static"
}

resource "azurerm_network_interface" "nic" {
  name                               = "jb-nic"
  location                           = "uksouth"
  resource_group_name                = "${var.rg}"

  ip_configuration {
    name                             = "jb-ip"
    subnet_id                        = "${azurerm_subnet.sub.id}"
    private_ip_address_allocation    = "dynamic"
    public_ip_address_id             = "${azurerm_public_ip.pip.id}"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                               = "jb"
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
    name                             = "jb-dsk"
    caching                          = "ReadWrite"
    create_option                    = "FromImage"
    managed_disk_type                = "Standard_LRS"
  }

  os_profile {
    computer_name                    = "jb"
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
