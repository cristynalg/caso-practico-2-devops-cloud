terraform {
  # Versión mínima de Terraform recomendada para este caso práctico.
  required_version = ">= 1.9.0"

  required_providers {
    # Provider oficial para crear recursos en Microsoft Azure.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Configuración del provider de Azure.
# Terraform usará la suscripción indicada para crear los recursos.
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# Grupo de recursos principal del caso práctico.
# Todos los recursos creados por Terraform se agruparán aquí.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}