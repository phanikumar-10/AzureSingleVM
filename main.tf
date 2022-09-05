locals {
  resource_group = "demo-rg"
  location       = "Central US"
  vm-name        = "${random_string.vm-name.result}-vm"
}

resource "random_string" "vm-name" {
  length = 6
  upper = false
  number = false
  lower = true
  special = false
}


resource "azurerm_resource_group" "demo-rg" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.demo-rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = local.vm-name
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_DS2"
  admin_username      = "demousr"
  admin_password      = "Azure@123"

  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface
  ]
}
