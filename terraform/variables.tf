variable "subscription_id" {
  description = "Identificador de la suscripción de Azure donde se crearán los recursos."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos principal del caso práctico."
  type        = string
  default     = "rg-cp2-cristina"
}

variable "location" {
  description = "Región de Azure donde se desplegarán los recursos."
  type        = string
  default     = "swedencentral"
}

variable "acr_name" {
  description = "Nombre único global del Azure Container Registry. Debe ir en minúsculas y sin guiones."
  type        = string
  default     = "cp2cristinaacr2026"
}

variable "tags" {
  description = "Etiquetas comunes para identificar los recursos del caso práctico."
  type        = map(string)

  default = {
    entorno  = "casopractico2"
    proyecto = "devops-cloud"
    alumna   = "cristina"
  }
}

variable "vm_name" {
  description = "Nombre de la máquina virtual Linux que se creará para el caso práctico."
  type        = string
  default     = "vm-cp2-cristina"
}

variable "admin_username" {
  description = "Usuario administrador que se utilizará para acceder por SSH a la máquina virtual."
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Tamaño de la máquina virtual del caso práctico. Se usa un tamaño pequeño para reducir el consumo de crédito de Azure Student."
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "ssh_public_key_path" {
  description = "Ruta local de la clave pública SSH que Terraform instalará en la máquina virtual."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}