output "key_vault_id" {
  description = "Id of the Key Vault"
  value       = one(azurerm_key_vault.this[*].id)

  depends_on = [
    azurerm_role_assignment.rbac_keyvault_administrator,
    azurerm_role_assignment.rbac_keyvault_reader,
    azurerm_role_assignment.rbac_keyvault_secrets_users,
  ]
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = one(azurerm_key_vault.this[*].name)
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = one(azurerm_key_vault.this[*].vault_uri)
}

output "key_vault_private_endpoint_id" {
  description = "ID of the Key Vault private endpoint"
  value       = one(azurerm_private_endpoint.this[*].id)
}
