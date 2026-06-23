# Azure Container Registry privado.
# Este registro se utilizará para almacenar las imágenes de contenedor
# que posteriormente descargarán la VM con Podman y el cluster AKS.
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # SKU Basic: opción más económica y suficiente para el caso práctico.
  sku = "Basic"

  # Se habilita el usuario administrador para simplificar la autenticación
  # desde Podman y Kubernetes durante el desarrollo del caso práctico.
  admin_enabled = true

  tags = var.tags
}