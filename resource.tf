resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Criação da VNet principal
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_config.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_config.address_space
}

# Criação Dinâmica de Subnets usando for_each
resource "azurerm_subnet" "subnets" {
  for_each = var.vnet_config.subnets

  name                 = each.key # Usa o nome definido na chave (ex: snet-frontend)
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = each.value.address_prefixes
}
