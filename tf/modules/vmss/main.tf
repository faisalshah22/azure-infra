terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = var.vmss_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.vm_size
  instances           = var.initial_instance_count
  zones               = length(var.zones) > 0 ? var.zones : null
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface {
    name    = "${var.vmss_name}-nic"
    primary = true

    ip_configuration {
      name                                    = "internal"
      primary                                 = true
      subnet_id                               = var.subnet_id
      load_balancer_backend_address_pool_ids  = var.load_balancer_backend_pool_ids
      load_balancer_inbound_nat_rules_ids     = []
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(var.cloud_init_script)

  tags = var.tags
}

resource "azurerm_virtual_machine_scale_set_extension" "enable_password_auth" {
  name                         = "enable-password-auth"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.main.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.1"
  auto_upgrade_minor_version   = true

  settings = jsonencode({
    script = base64encode(<<-EOF
      #!/bin/bash
      echo "${var.admin_username}:${var.admin_password}" | chpasswd
      sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
      sed -i 's/PasswordAuthentication no/#PasswordAuthentication no/' /etc/ssh/sshd_config
      systemctl restart sshd
    EOF
    )
  })
}

# Automatically update VMSS instances to register with Load Balancer backend pool
resource "null_resource" "vmss_register_with_lb" {
  count = length(var.load_balancer_backend_pool_ids) > 0 ? 1 : 0

  triggers = {
    vmss_id                = azurerm_linux_virtual_machine_scale_set.main.id
    instance_count         = azurerm_linux_virtual_machine_scale_set.main.instances
    backend_pool_ids       = join(",", var.load_balancer_backend_pool_ids)
    extension_id           = azurerm_virtual_machine_scale_set_extension.enable_password_auth.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for VMSS instances to be provisioned
      echo "Waiting for VMSS instances to be ready..."
      MAX_RETRIES=30
      RETRY_COUNT=0
      
      while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        INSTANCE_COUNT=$(az vmss list-instances \
          --resource-group ${var.resource_group_name} \
          --name ${azurerm_linux_virtual_machine_scale_set.main.name} \
          --query "length([?provisioningState=='Succeeded'])" -o tsv 2>/dev/null || echo "0")
        
        if [ "$INSTANCE_COUNT" -ge "${azurerm_linux_virtual_machine_scale_set.main.instances}" ]; then
          echo "All VMSS instances are ready (count: $INSTANCE_COUNT)"
          break
        fi
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Waiting for VMSS instances... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 10
      done
      
      # Get all instance IDs
      INSTANCE_IDS=$(az vmss list-instances \
        --resource-group ${var.resource_group_name} \
        --name ${azurerm_linux_virtual_machine_scale_set.main.name} \
        --query "[].instanceId" -o tsv 2>/dev/null || echo "")
      
      # Update all instances to register with Load Balancer
      if [ -n "$INSTANCE_IDS" ]; then
        echo "Updating VMSS instances to register with Load Balancer..."
        az vmss update-instances \
          --resource-group ${var.resource_group_name} \
          --name ${azurerm_linux_virtual_machine_scale_set.main.name} \
          --instance-ids $INSTANCE_IDS
        echo "VMSS instances updated successfully"
      else
        echo "Warning: No VMSS instances found to update"
      fi
    EOT
  }

  depends_on = [
    azurerm_linux_virtual_machine_scale_set.main,
    azurerm_virtual_machine_scale_set_extension.enable_password_auth
  ]
}

resource "azurerm_monitor_autoscale_setting" "vmss" {
  count               = var.autoscaling_enabled ? 1 : 0
  name                = "${var.vmss_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id
  enabled             = true

  profile {
    name = "default"

    capacity {
      default = var.autoscale_min_capacity
      minimum = var.autoscale_min_capacity
      maximum = var.autoscale_max_capacity
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.autoscale_cpu_threshold_scale_out
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.autoscale_cpu_threshold_scale_in
        metric_namespace   = "Microsoft.Compute/virtualMachineScaleSets"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator  = false
      custom_emails                          = var.autoscale_notification_emails
    }
  }
}
