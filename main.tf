# 1. Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Resource Group Baru (Berbeda dari manual)
resource "azurerm_resource_group" "rg" {
  name     = "jarvis-rg-tf"
  location = "Indonesia Central"
}

# 3. Virtual Network & Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "VM-jarvis-vnet-tf"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Public IP
resource "azurerm_public_ip" "pip" {
  name                = "VM-jarvis-ip-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5. Network Interface (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "VM-jarvis-nic-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# 6. Virtual Machine (Standard_B2s: 2 vCPU, 4 GiB Memory)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "VM-jarvis-tf"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "visvis"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  tags = {
    Environment = "Learning"
    Day         = "4"
    Owner       = "Jarvis"
  }

  admin_ssh_key {
    username   = "visvis"
    public_key = file("C:/Users/Jarvis/OneDrive - Bina Nusantara/Internship-AGIT/Task/VM-jarvis_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# 7. Output Alamat IP Publik
output "public_ip_address" {
  value       = azurerm_linux_virtual_machine.vm.public_ip_address
  description = "Alamat IP Publik untuk akses SSH ke VM Terraform"
}