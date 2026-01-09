variable "location" {
  description = "Azure region"
  type        = string
}

variable "vm_private_ip" {
  description = "Private IP address of the VM (fallback if quotes state not available)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

