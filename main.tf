data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  count = module.this.enabled && var.location == null ? 1 : 0

  name = var.resource_group_name
}

resource "azurerm_key_vault" "this" {
  # checkov:skip=CKV_AZURE_109: Ensure that key vault allows firewall rules settings
  count = module.this.enabled ? 1 : 0

  name = local.name_from_descriptor

  location            = local.location
  resource_group_name = local.resource_group_name

  tenant_id = data.azurerm_client_config.current.tenant_id

  sku_name = var.sku_name

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  enable_rbac_authorization = var.rbac_authorization_enabled

  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]
    iterator = acl

    content {
      bypass                     = acl.value.bypass
      default_action             = acl.value.default_action
      ip_rules                   = acl.value.ip_rules
      virtual_network_subnet_ids = acl.value.virtual_network_subnet_ids
    }
  }

  tags = module.this.tags
}

resource "azurerm_private_endpoint" "this" {
  count = module.this.enabled && var.private_endpoint.enabled ? 1 : 0

  location            = var.location
  name                = local.private_link_name_from_descriptor
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    is_manual_connection           = false
    name                           = local.private_link_name_from_descriptor
    private_connection_resource_id = one(azurerm_key_vault.this[*].id)
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.private_endpoint.private_dns_zone_ids
  }

  tags = module.this.tags
}

resource "azurerm_role_assignment" "rbac_keyvault_administrator" {
  for_each = toset(module.this.enabled && var.rbac_authorization_enabled ? var.admin_objects_ids : [])

  scope                = one(azurerm_key_vault.this[*].id)
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "rbac_keyvault_secrets_users" {
  for_each = toset(module.this.enabled && var.rbac_authorization_enabled ? var.reader_objects_ids : [])

  scope                = one(azurerm_key_vault.this[*].id)
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "rbac_keyvault_reader" {
  for_each = toset(module.this.enabled && var.rbac_authorization_enabled ? var.reader_objects_ids : [])

  scope                = one(azurerm_key_vault.this[*].id)
  role_definition_name = "Key Vault Reader"
  principal_id         = each.value
}

module "diagnostic_settings" {
  count = module.this.enabled && var.diagnostics_setting.enabled ? 1 : 0

  source  = "claranet/diagnostic-settings/azurerm"
  version = "6.5.0"

  resource_id = one(azurerm_key_vault.this[*].id)
  logs_destinations_ids = [
    var.diagnostics_setting.workspace_resource_id
  ]
}
