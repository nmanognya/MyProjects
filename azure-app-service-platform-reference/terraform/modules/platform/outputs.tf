output "web_app_name" {
  description = "Azure Linux Web App name."
  value       = azurerm_linux_web_app.this.name
}

output "web_app_default_hostname" {
  description = "Default App Service hostname."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "web_app_principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}

output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = azurerm_key_vault.this.id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.this.id
}
