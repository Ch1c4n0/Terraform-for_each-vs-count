# Terraform — `for_each` vs `count`

> Exemplo prático de uso do `for_each` no Terraform para provisionar recursos Azure de forma dinâmica:  
> **Resource Group → Virtual Network → Subnets (com NSG opcional)**

---

## Estrutura do projeto

```
.
├── main.tf        # Provider e versão do Terraform
├── variables.tf   # Variáveis de entrada (incluindo mapa de subnets)
├── resource.tf    # Recursos Azure criados com for_each
├── output.tf      # Outputs com IDs dos recursos criados
└── README.md
```

---

## Pré-requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.3
- [Azure CLI](https://learn.microsoft.com/pt-br/cli/azure/install-azure-cli) autenticado (`az login`)
- Subscription ID do Azure

---

## Como usar

```bash
# 1. Edite main.tf e substitua "YourSubscriptionID" pelo seu Subscription ID
# 2. Inicialize o Terraform
terraform init

# 3. Verifique o plano
terraform plan

# 4. Aplique
terraform apply
```

---

## Explicação de cada arquivo

### `main.tf` — Provider e versão do Terraform

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.50.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "YourSubscriptionID"
}
```

**O que faz:**  
- Declara que o projeto usa o provider `azurerm` da HashiCorp, versão `~> 3.50.0` (aceita patches, mas não major/minor).
- Configura as credenciais de acesso à subscription Azure.

---

### `variables.tf` — Variáveis de entrada

```hcl
variable "vnet_config" {
  type = object({
    name          = string
    address_space = list(string)
    subnets = map(object({
      address_prefixes = list(string)
      security_group   = bool
    }))
  })
  ...
}
```

**O que faz:**  
- Define um tipo complexo (`object` com `map` interno) para descrever a VNet e todas as suas subnets em um único bloco.
- Cada entrada do mapa `subnets` possui:
  - `address_prefixes` — CIDR da subnet
  - `security_group` — flag booleana para indicar se um NSG deve ser associado

**Por que assim?**  
Agrupar a configuração em um único `object` centraliza as definições e facilita a passagem de valores via `terraform.tfvars` ou módulos, sem precisar gerenciar variáveis separadas para cada subnet.

---

### `resource.tf` — Recursos Azure com `for_each`

```hcl
resource "azurerm_subnet" "subnets" {
  for_each = var.vnet_config.subnets

  name                 = each.key
  address_prefixes     = each.value.address_prefixes
  ...
}
```

**O que faz:**  
- Cria uma instância de `azurerm_subnet` **para cada entrada** do mapa `subnets`.
- `each.key` → nome da subnet (ex: `snet-frontend`)
- `each.value` → objeto com `address_prefixes` e `security_group`

---

## `for_each` vs `count` — Quando usar cada um?

| Critério | `count` | `for_each` |
|---|---|---|
| **Tipo de entrada** | Número inteiro | `set(string)` ou `map(any)` |
| **Acesso ao item** | `count.index` (posição numérica) | `each.key` / `each.value` (identificador semântico) |
| **Identificação no state** | `resource[0]`, `resource[1]` | `resource["snet-frontend"]` |
| **Remover 1 item do meio** | ⚠️ Recria todos os recursos seguintes | ✅ Remove apenas o item removido |
| **Mapa/objeto de entrada** | ✅ Simples de usar com listas simples | ✅ Ideal com mapas e objetos |
| **Legibilidade** | Fraca (índice numérico) | Alta (nome do recurso) |

### Por que preferir `for_each`?

1. **Estado estável** — cada recurso é identificado pela sua *chave*, não pela *posição*. Remover `snet-backend` de uma lista com `count` destruiria e recriaria `snet-frontend` (shift de índices). Com `for_each`, apenas `snet-backend` é removido.

2. **Rastreabilidade** — no `terraform state list` você vê `azurerm_subnet.subnets["snet-frontend"]` em vez de `azurerm_subnet.subnets[0]`, facilitando auditoria e debugging.

3. **Expressividade** — o código descreve **o que** está sendo criado, não **quantos** itens.

4. **Mapas com metadados** — `for_each` itera sobre maps, permitindo que cada item carregue atributos extras (como `security_group = true`), impossível de fazer nativamente com `count`.

### Quando ainda usar `count`?

- Criar N réplicas idênticas (ex: 3 VMs de carga idênticas onde a posição não importa).
- Recursos condicionais: `count = var.enable_feature ? 1 : 0`.

---

## Outputs

Após `terraform apply`, os outputs retornam:

```hcl
vnet_id    = "/subscriptions/.../virtualNetworks/vnet-corporativa"
subnet_ids = {
  "AzureFirewallSubnet" = "/subscriptions/.../subnets/AzureFirewallSubnet"
  "snet-backend"        = "/subscriptions/.../subnets/snet-backend"
  "snet-frontend"       = "/subscriptions/.../subnets/snet-frontend"
}
```

O output usa uma **for expression** (`{ for k, v in ... : k => v.id }`) para transformar o mapa de recursos em um mapa de IDs — técnica complementar ao `for_each`.

---

## Licença

MIT
