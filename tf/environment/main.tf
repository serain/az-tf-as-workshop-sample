# Entrypoint and main project file. We're using it to call other terraform
# modules defined in `modules/`

module "vnet" {
  source             = "../modules/vnet"
}

module "sub-mgmt" {
  source             = "../modules/sub-mgmt"
  rg                 = "${module.vnet.rg}"
  vm_user            = "${var.vm_user}"
  vm_ssh_key         = "${var.vm_ssh_key}"
}

module "sub-front" {
  source             = "../modules/sub-front"
  rg                 = "${module.vnet.rg}"
  vm_user            = "${var.vm_user}"
  vm_ssh_key         = "${var.vm_ssh_key}"
}

module "sub-back" {
  source             = "../modules/sub-back"
  rg                 = "${module.vnet.rg}"
  vm_user            = "${var.vm_user}"
  vm_ssh_key         = "${var.vm_ssh_key}"
}
