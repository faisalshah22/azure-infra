variable "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
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

variable "subnet_id" {
  description = "ID of the subnet for the VMSS"
  type        = string
}

variable "load_balancer_backend_pool_ids" {
  description = "List of Load Balancer backend pool IDs to attach VMSS instances to"
  type        = list(string)
  default     = []
}

variable "vm_size" {
  description = "Size of the VMs in the scale set"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "initial_instance_count" {
  description = "Initial number of VM instances"
  type        = number
  default     = 2
}

variable "zones" {
  description = "Availability zones for the VMSS (list of zone numbers: [1, 2, 3])"
  type        = list(number)
  default     = [1, 2, 3]
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
}

variable "admin_password" {
  description = "Admin password for VM access"
  type        = string
  sensitive   = true
}

variable "cloud_init_script" {
  description = "Cloud-init script for VM initialization"
  type        = string
}

variable "os_disk_storage_account_type" {
  description = "Storage account type for OS disk. Use Premium_LRS for better performance and HA."
  type        = string
  default     = "Premium_LRS"
}

variable "autoscaling_enabled" {
  description = "Enable autoscaling for the VMSS"
  type        = bool
  default     = true
}

variable "autoscale_min_capacity" {
  description = "Minimum number of VM instances"
  type        = number
  default     = 2
}

variable "autoscale_max_capacity" {
  description = "Maximum number of VM instances"
  type        = number
  default     = 10
}

variable "autoscale_cpu_threshold_scale_out" {
  description = "CPU threshold percentage to scale out (add more VMs)"
  type        = number
  default     = 70
}

variable "autoscale_cpu_threshold_scale_in" {
  description = "CPU threshold percentage to scale in (remove VMs)"
  type        = number
  default     = 30
}

variable "autoscale_notification_emails" {
  description = "List of email addresses to notify on autoscale events"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
