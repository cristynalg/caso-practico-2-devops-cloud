variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource group name for the case study"
  type        = string
  default     = "rg-cp2-cristina"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name"
  type        = string
  default     = "cp2cristinaacr2026"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)

  default = {
    environment = "casopractico2"
    project     = "devops-cloud"
  }
}