data "azurerm_client_config" "current" {}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "resource_group" {
  source  = "github.com/getindata/terraform-azurerm-resource-group?ref=v1.2.0"
  context = module.this.context

  name     = var.resource_group_name
  location = var.location
}

module "vnet" {
  source              = "github.com/Azure/terraform-azurerm-vnet?ref=3.0.0"
  resource_group_name = module.resource_group.name
  vnet_location       = module.resource_group.location
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = module.this.id
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = module.this.tags
  sku                 = "PerGB2018"
}

resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.resource_group.name
}

module "key_vault" {
  source  = "../../"
  context = module.this.context

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  admin_objects_ids = [data.azurerm_client_config.current.object_id]

  diagnostics_setting = {
    enabled               = true
    workspace_resource_id = azurerm_log_analytics_workspace.this.id
  }

  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  public_network_access_enabled = true
  network_acls = {
    ip_rules = [chomp(data.http.myip.body)]
  }

  private_endpoint = {
    enabled              = true
    subnet_id            = module.vnet.vnet_subnets[0]
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
}

resource "azurerm_key_vault_secret" "foo" {
  key_vault_id    = module.key_vault.key_vault_id
  name            = "foo"
  value           = "bar"
  expiration_date = "2023-12-30T20:00:00Z"
  content_type    = "Example content"
}
