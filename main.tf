terraform {
	required_providers {
		azurerm = {
			source  = "hashicorp/azurerm"
			version = "=2.41.0"
		}
	}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "common" {
  name     = var.prefix
  location = "East US2"
}

resource "azurerm_virtual_network" "common" {
  name                = join("-", [var.prefix, "vnet"])
  address_space       = ["172.10.0.0/16"]
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name
}

resource "azurerm_subnet" "common" {
  name                 =  join("-", [var.prefix, "subnet"])
  resource_group_name  = azurerm_resource_group.common.name
  virtual_network_name = azurerm_virtual_network.common.name
  address_prefixes     = ["172.10.1.0/24"]
}

resource "azurerm_network_security_group" "common" {
  name                = join("-", [var.prefix, "nsg"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name
}

resource "azurerm_subnet_network_security_group_association" "common" {
  subnet_id                 = azurerm_subnet.common.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_public_ip" "proxynoauth" {
  name                = join("-", [var.prefix, "proxynoauthpip"])
  resource_group_name = azurerm_resource_group.common.name
  location            = azurerm_resource_group.common.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "proxybasic" {
  name                = join("-", [var.prefix, "proxybasicpip"])
  resource_group_name = azurerm_resource_group.common.name
  location            = azurerm_resource_group.common.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "proxycert" {
  name                = join("-", [var.prefix, "proxycertpip"])
  resource_group_name = azurerm_resource_group.common.name
  location            = azurerm_resource_group.common.location
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "cluster" {
  name                = join("-", [var.prefix, "clusterpip"])
  resource_group_name = azurerm_resource_group.common.name
  location            = azurerm_resource_group.common.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "proxynoauth" {
  name                = join("-", [var.prefix, "proxnoauthnic"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  ip_configuration {
    name                          = "configuration1"
    subnet_id                     = azurerm_subnet.common.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.proxynoauth.id
  }
}

resource "azurerm_network_interface_security_group_association" "proxynoauth" {
  network_interface_id      = azurerm_network_interface.proxynoauth.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_network_interface" "proxybasic" {
  name                = join("-", [var.prefix, "proxybasicnic"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  ip_configuration {
    name                          = "configuration2"
    subnet_id                     = azurerm_subnet.common.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.proxybasic.id
  }
}

resource "azurerm_network_interface_security_group_association" "proxybasic" {
  network_interface_id      = azurerm_network_interface.proxybasic.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_network_interface" "proxycert" {
  name                = join("-", [var.prefix, "proxycertnic"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  ip_configuration {
    name                          = "configuration3"
    subnet_id                     = azurerm_subnet.common.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.proxycert.id
  }
}

resource "azurerm_network_interface_security_group_association" "proxycert" {
  network_interface_id      = azurerm_network_interface.proxycert.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_network_interface" "cluster" {
  name                = join("-", [var.prefix, "clusternic"])
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  ip_configuration {
    name                          = "configuration3"
    subnet_id                     = azurerm_subnet.common.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.cluster.id
  }
}

resource "azurerm_network_interface_security_group_association" "cluster" {
  network_interface_id      = azurerm_network_interface.cluster.id
  network_security_group_id = azurerm_network_security_group.common.id
}

resource "azurerm_storage_account" "common" {
  name                     = join("", [var.prefix, "sa"])
  resource_group_name      = azurerm_resource_group.common.name
  location                 = azurerm_resource_group.common.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "common" {
  name                  = join("", [var.prefix, "sc"])
  storage_account_name  = azurerm_storage_account.common.name
  container_access_type = "private" 
}

resource "azurerm_virtual_machine" "proxynoauth" {
  name                  = join("-", [var.prefix, "proxynoauthvm"])
  location              = azurerm_resource_group.common.location
  resource_group_name   = azurerm_resource_group.common.name
  network_interface_ids = [azurerm_network_interface.proxynoauth.id]
  vm_size               = "Standard_B2ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "noauthdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "proxynoauth"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data  = file(var.publickeypath)
      path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }

  boot_diagnostics{
    enabled = true
    storage_uri = azurerm_storage_account.common.primary_blob_endpoint
  }
}

resource "azurerm_virtual_machine_extension" "proxynoauth" {
  name                 = join("-", [var.prefix, "noauthextension"])
  virtual_machine_id   = azurerm_virtual_machine.proxynoauth.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "fileUris": [
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/scripts/squid/noauth.sh",
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/conf/squid-noauth.conf"
    ],
    "commandToExecute": "sudo bash ./noauth.sh"
  })
}

resource "azurerm_virtual_machine" "proxybasic" {
  name                  = join("-", [var.prefix, "proxybasicvm"])
  location              = azurerm_resource_group.common.location
  resource_group_name   = azurerm_resource_group.common.name
  network_interface_ids = [azurerm_network_interface.proxybasic.id]
  vm_size               = "Standard_B2ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "basicdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "proxybasic"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data  = file(var.publickeypath)
      path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }

  boot_diagnostics{
    enabled = true
    storage_uri = azurerm_storage_account.common.primary_blob_endpoint
  }
}

resource "azurerm_virtual_machine_extension" "proxybasic" {
  name                 = join("-", [var.prefix, "basicextension"])
  virtual_machine_id   = azurerm_virtual_machine.proxybasic.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "fileUris": [
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/scripts/squid/basic.sh",
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/conf/squid-basic.conf"
    ],
    "commandToExecute": join(" ", ["sudo bash ./basic.sh", join("", [var.prefix, "welcome"])])
  })
}

resource "azurerm_virtual_machine" "proxycert" {
  name                  = join("-", [var.prefix, "proxycertvm"])
  location              = azurerm_resource_group.common.location
  resource_group_name   = azurerm_resource_group.common.name
  network_interface_ids = [azurerm_network_interface.proxycert.id]
  vm_size               = "Standard_B2ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "certdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "proxycert"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data  = file(var.publickeypath)
      path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }

  boot_diagnostics{
    enabled = true
    storage_uri = azurerm_storage_account.common.primary_blob_endpoint
  }
}

resource "azurerm_virtual_machine_extension" "proxycert" {
  name                 = join("-", [var.prefix, "certextension"])
  virtual_machine_id   = azurerm_virtual_machine.proxycert.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "fileUris": [
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/scripts/squid/cert.sh",
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/conf/squid-cert.conf"
    ],
    "commandToExecute": join(" ", ["sudo bash ./cert.sh", azurerm_network_interface.proxycert.private_ip_address])
  })
}

resource "azurerm_virtual_machine" "cluster" {
  name                  = join("-", [var.prefix, "clustervm"])
  location              = azurerm_resource_group.common.location
  resource_group_name   = azurerm_resource_group.common.name
  network_interface_ids = [azurerm_network_interface.cluster.id]
  vm_size               = "Standard_B4ms"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "clusterdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "cluster"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data  = file(var.publickeypath)
      path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }

  boot_diagnostics{
    enabled = true
    storage_uri = azurerm_storage_account.common.primary_blob_endpoint
  }
}

resource "azurerm_virtual_machine_extension" "cluster" {
  name                 = join("-", [var.prefix, "clusterextension"])
  virtual_machine_id   = azurerm_virtual_machine.cluster.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = jsonencode({
    "fileUris": [
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/scripts/cluster/main.sh",
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/scripts/cluster/prepare-cluster-node.sh",
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/scripts/cluster/bootstrap-master-node.sh",
      "https://raw.githubusercontent.com/daweim0/proxy-simulation/master/scripts/cluster/install-utils.sh"
    ],
    "commandToExecute": join(" ", ["sudo bash ./main.sh", azurerm_network_interface.proxynoauth.private_ip_address, azurerm_network_interface.proxybasic.private_ip_address, azurerm_network_interface.proxycert.private_ip_address, var.connectedk8s_source, var.k8s_extension_source, var.k8sconfiguration_source])
  })
}