output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  # Retorna um mapa com Nome da Subnet => ID gerado no Azure
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}
