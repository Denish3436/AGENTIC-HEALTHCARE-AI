variable "name" {
  description = "Name of the container registry"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "SKU tier for ACR"
  type        = string
  default     = "Standard"
}

variable "georeplication_locations" {
  description = "Geo-replication locations for Premium SKU"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
