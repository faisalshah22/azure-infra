variable "location" {
  description = "Azure region"
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = null
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = null
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = null
}

variable "app_gateway_subnet_cidr" {
  description = "CIDR block for Application Gateway subnet"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = null
}

