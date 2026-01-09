variable "location" {
  description = "Azure region"
  type        = string
}

variable "lb_zones" {
  description = "Availability zones for Load Balancer (list of zone numbers: [1, 2, 3])"
  type        = list(number)
  default     = [1, 2, 3]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

