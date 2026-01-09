variable "lb_name" {
  description = "Name of the Azure Load Balancer"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network (for reference, VMSS will be connected via backend pool)"
  type        = string
}

variable "zones" {
  description = "Availability zones for Load Balancer (list of zone numbers: [1, 2, 3])"
  type        = list(number)
  default     = [1, 2, 3]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
