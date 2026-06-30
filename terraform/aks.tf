# Define el clúster AKS gestionado por Azure.
# El clúster tendrá un único nodo worker para cumplir el enunciado y reducir consumo.
# También se asigna el rol AcrPull a la identidad kubelet para que AKS pueda descargar
# imágenes privadas desde el Azure Container Registry sin usar credenciales en los YAML.


# Cluster AKS gestionado por Azure para desplegar la aplicación Kubernetes
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cp2-cristina"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akscp2cristina"

  # Se utiliza el tier Free para ajustar el despliegue al entorno de Azure for Students
  sku_tier = "Free"

  # Se define un único nodo worker para cumplir el requisito del caso práctico y reducir consumo
  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }
  # Se crea una identidad administrada para el cluster AKS
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Se asigna el rol AcrPull a la identidad kubelet de AKS sobre el ACR privado.
# Esto permite que los nodos del cluster descarguen imágenes del ACR,
# sin conceder permisos para subir imágenes ni administrar el registro.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}