# Nombre del grupo de recursos creado por Terraform.
output "resource_group_name" {
  description = "Nombre del grupo de recursos creado."
  value       = azurerm_resource_group.rg.name
}

# Nombre del Azure Container Registry.
output "acr_name" {
  description = "Nombre del Azure Container Registry creado."
  value       = azurerm_container_registry.acr.name
}

# Servidor de login del ACR.
# Se usará para etiquetar, subir y descargar imágenes de contenedor.
output "acr_login_server" {
  description = "Servidor de login del Azure Container Registry."
  value       = azurerm_container_registry.acr.login_server
}

# Usuario administrador del ACR.
# Se marca como sensible para evitar mostrarlo accidentalmente.
output "acr_admin_username" {
  description = "Usuario administrador del Azure Container Registry."
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

# Contraseña administrador del ACR.
# Se marca como sensible porque es una credencial.
output "acr_admin_password" {
  description = "Contraseña del usuario administrador del Azure Container Registry."
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "vm_public_ip" {
  description = "IP pública de la máquina virtual creada para el caso práctico."
  value       = azurerm_public_ip.public_ip.ip_address
}

output "vm_admin_username" {
  description = "Usuario administrador configurado para acceder por SSH a la máquina virtual."
  value       = var.admin_username
}