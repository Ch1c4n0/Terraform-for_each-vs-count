variable "resource_group_name" {
  default = "rg-infra-producao"
}

variable "location" {
  default = "Brazil South"
}

variable "vnet_config" {
  description = "Configuração da VNet e suas Subnets"
  type = object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      address_prefixes = list(string)
      security_group   = bool # Define se deve associar um NSG
    }))
  })

  default = {
    name          = "vnet-corporativa"
    address_space = ["10.0.0.0/16"]
    subnets = {
      "snet-frontend"       = { address_prefixes = ["10.0.1.0/24"], security_group = true }
      "snet-backend"        = { address_prefixes = ["10.0.2.0/24"], security_group = true }
      "AzureFirewallSubnet" = { address_prefixes = ["10.0.10.0/24"], security_group = false }
    }
  }
}
