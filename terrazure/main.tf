# main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}


# flat resources and groups

locals {
  farmgroups = {
    "azin" = {
      reg_suffix  = "in"
      location    = "Central India"
    }
    "azbr" = {
      reg_suffix  = "br"
      location    = "Brazil South"
    }
  }
}

resource "azurerm_resource_group" "farm_group" {
  for_each = local.farmgroups
  name = each.key  
  location = each.value.location
}

resource "azurerm_virtual_network" "farm_net" {
  for_each = local.farmgroups
  name                = "${each.key}Net"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.farm_group[each.key].location
  resource_group_name = azurerm_resource_group.farm_group[each.key].name
}

resource "azurerm_subnet" "farm_subnet" {
  for_each = local.farmgroups
  name                  = "${each.key}Subnet"
  address_prefixes      = ["10.10.1.0/24"]
  resource_group_name   = azurerm_resource_group.farm_group[each.key].name
  virtual_network_name  = azurerm_virtual_network.farm_net[each.key].name
}



################### 2nd apply ################### 


## 2d resources

locals {
  farm_groups = azurerm_resource_group.farm_group 
  vm_idxx   = [ 0, 1, 2 ]
  group_vms = distinct(flatten([
    for farm_group in local.farm_groups : [ 
      for vm_idx in local.vm_idxx : { 
        farm_group = farm_group
        vm_idx = vm_idx
      }
    ]
  ]))
}

resource "azurerm_public_ip" "farm_pub_ip" {
  for_each = { for i in local.group_vms: "${i.farm_group.name}.${i.vm_idx}" => i }
  name                = "${each.value.farm_group.name}PubIp${each.value.vm_idx}"
  resource_group_name = each.value.farm_group.name 
  location            = each.value.farm_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "farm_nic" {
  for_each = { 
    for i in local.group_vms: "${i.farm_group.name}.${i.vm_idx}" => i 
  }
  name                = "${each.value.farm_group.name}Nic${each.value.vm_idx}"
  resource_group_name = each.value.farm_group.name 
  location            = each.value.farm_group.location
  ip_configuration {
    name = "${each.value.farm_group.name}NicConf${each.value.vm_idx}"
    subnet_id                     = azurerm_subnet.farm_subnet[
      "${each.value.farm_group.name}"].id
    public_ip_address_id          = azurerm_public_ip.farm_pub_ip[
      "${each.value.farm_group.name}.${each.value.vm_idx}"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "farm_nic_sec" {
  for_each = { 
    for i in local.group_vms: "${i.farm_group.name}.${i.vm_idx}" => i 
  }
  name                = "${each.value.farm_group.name}NicSec${each.value.vm_idx}"
  resource_group_name = each.value.farm_group.name 
  location            = each.value.farm_group.location
  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# bind security group to vm's interface
resource "azurerm_network_interface_security_group_association" "farm_nic_sec_bind" {
  for_each = { 
    for i in local.group_vms: "${i.farm_group.name}.${i.vm_idx}" => i 
  }
  network_interface_id = azurerm_network_interface.farm_nic[
    "${each.value.farm_group.name}.${each.value.vm_idx}"].id
  network_security_group_id = azurerm_network_security_group.farm_nic_sec[
    "${each.value.farm_group.name}.${each.value.vm_idx}"].id
}

# vm itself
resource "azurerm_linux_virtual_machine" "farm_vm" {
  for_each = { 
    for i in local.group_vms: "${i.farm_group.name}.${i.vm_idx}" => i 
  }
  name                  = "${each.value.farm_group.name}${each.value.vm_idx}"
  resource_group_name = each.value.farm_group.name 
  location            = each.value.farm_group.location
  network_interface_ids = [ 
    azurerm_network_interface.farm_nic[
      "${each.value.farm_group.name}.${each.value.vm_idx}"].id,
  ]
  size                  = "Standard_B1s"
  admin_username        = var.admin_name
  admin_password        = var.admin_pw
  disable_password_authentication = false

  os_disk {
    name = "${each.value.farm_group.name}Vm${each.value.vm_idx}OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-11"
    sku       = "11-gen2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "farm_init_script" {
  for_each = { 
    for i in local.group_vms: "${i.farm_group.name}.${i.vm_idx}" => i 
  }
  name = "${each.value.farm_group.name}${each.value.vm_idx}InitScript"
  virtual_machine_id   = azurerm_linux_virtual_machine.farm_vm[
    "${each.value.farm_group.name}.${each.value.vm_idx}"].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  settings = <<SETTINGS
    {
      "commandToExecute": "${
        "apt -y update && apt -y upgrade "                    }${
        var.install_spec_soft                                 }${
        " && exit 0"}"
    }
    SETTINGS
}

