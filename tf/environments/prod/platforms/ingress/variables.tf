variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "vm_private_ip" {
  description = "Private IP address of the VM (fallback if quotes state not available)"
  type        = string
  default     = "10.0.2.10"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

