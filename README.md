# Azure Infrastructure - Quotes Application

Terraform infrastructure for deploying a highly available FastAPI quotes application on Microsoft Azure. This architecture implements a three-tier deployment model with network isolation, automated application deployment, and comprehensive security measures.

**Status**: Successfully deployed to Azure Cloud and tested. All components are operational and verified.

**High Availability**: The infrastructure implements full High Availability (HA) with autoscaling, zone redundancy, and automated failover capabilities.

## Architecture Overview

```
Internet
  ↓
Azure Load Balancer (Standard SKU, Public IP)
  ↓
Virtual Machine Scale Set (VMSS) - Auto-scaling
  ├── VM Instance 1 (Port 8000)
  ├── VM Instance 2 (Port 8000)
  └── Auto-scaled instances (2-10 based on CPU)
  ↓
Azure SQL Database (Private Endpoint, VNet-only access)
```

### Components

- **Azure Load Balancer**: Standard SKU load balancer with public IP, routing HTTP traffic to VMSS instances
- **Virtual Machine Scale Set (VMSS)**: Auto-scaling Linux VMs (Ubuntu 22.04 LTS) running FastAPI application
- **Azure SQL Database**: Managed SQL Server with Private Endpoint (no public access)
- **Key Vault**: Automated secret generation and secure storage for credentials
- **Network Security Groups (NSG)**: Restrictive firewall rules for ingress traffic
- **Log Analytics Workspace**: Centralized logging and monitoring
- **Cloud-init**: Automated application deployment on every VM instance

## High Availability (HA) Features

### Application Layer (VMSS)
- **Minimum 2 Instances**: Ensures redundancy and fault tolerance
- **Auto-scaling**: Automatically scales from 2 to 10 instances based on CPU usage
  - **Scale Out**: When average CPU > 70% for 5 minutes, adds 1 VM
  - **Scale In**: When average CPU < 30% for 5 minutes, removes 1 VM
- **Automatic Load Balancer Integration**: All VMSS instances (including new ones from autoscaling) are automatically added to the Load Balancer backend pool
- **Health Probes**: Load Balancer monitors VM health and routes traffic only to healthy instances
- **Zero-Downtime Scaling**: New VMs are added to the Load Balancer as soon as they're healthy

### Database Layer (SQL)
- **Standard S2 Tier**: Production-grade database with 99.99% SLA
- **Geo-Backup Enabled**: Automatic backups with geo-redundancy
- **Short-term Retention**: 7 days of point-in-time restore capability
- **Private Endpoint**: Database accessible only within VNet (no public access)
- **Transparent Data Encryption (TDE)**: Automatic encryption at rest

### Network Layer (Load Balancer)
- **Standard SKU**: Zone-redundant load balancer with high availability
- **Health Probes**: HTTP probes on port 8000, checking `/` endpoint every 15 seconds
- **Automatic Backend Discovery**: VMSS instances automatically registered in backend pool
- **Traffic Distribution**: Even distribution across healthy backend instances

## Network Security (NSG Rules)

The infrastructure implements strict network security through NSG rules:

### Inbound Rules (Priority Order)

1. **AllowAppGatewayToVM** (Priority 1000)
   - **Source**: App Gateway subnet (10.0.3.0/24)
   - **Destination**: Port 8000
   - **Purpose**: Allow traffic from Application Gateway subnet (legacy support)

2. **AllowLoadBalancerToVM** (Priority 1002)
   - **Source**: `AzureLoadBalancer` service tag
   - **Destination**: Port 8000
   - **Purpose**: Allow Azure Load Balancer health probes

3. **AllowInternetToVM** (Priority 1003)
   - **Source**: `*` (all sources)
   - **Destination**: Port 8000
   - **Purpose**: Allow client traffic from Load Balancer (after NAT)

### Outbound Rules

1. **AllowVMToSQL** (Priority 1001)
   - **Source**: All VMs
   - **Destination**: Port 1433 (SQL)
   - **Purpose**: Allow VMSS instances to connect to SQL Database

### Security Best Practices

- **No Public IPs on VMs**: All VMs are in private subnet, accessible only via Load Balancer
- **SQL Private Endpoint**: Database has no public access, only accessible within VNet
- **Key Vault Network Restrictions**: Key Vault accessible only from VNet and specific IPs
- **Service Endpoints**: Microsoft.Sql and Microsoft.KeyVault service endpoints enabled on private subnet

## Folder Structure

```
azure-infra/
├── app/                          # Application source code
│   ├── app.py                   # FastAPI application
│   ├── requirements.txt         # Python dependencies
│   ├── init-db.sql             # Database schema and seed data
│   ├── Dockerfile               # Multi-stage Dockerfile
│   └── README.md               # Application documentation
│
├── tf/                          # Terraform infrastructure
│   ├── modules/                 # Reusable Terraform modules
│   │   ├── vpc/                # Virtual Network and Subnets
│   │   ├── nsg/                # Network Security Groups
│   │   ├── load-balancer/      # Azure Load Balancer
│   │   ├── vmss/               # Virtual Machine Scale Set
│   │   ├── sql/                # Azure SQL Database
│   │   └── monitoring/         # Log Analytics Workspace
│   │
│   └── environments/
│       └── prod/
│           ├── landing-zones/
│           │   └── connectivity/    # VNet, Subnets
│           ├── platforms/
│           │   └── ingress/         # Load Balancer
│           └── products/
│               └── quotes/          # VMSS, SQL, NSGs, Monitoring
│
├── setup-backend.sh            # Automated Terraform backend setup
└── README.md                   # This file
```

## Prerequisites

- **Azure CLI** installed and authenticated (`az login`)
- **Terraform** >= 1.0
- **Azure Subscription** with contributor permissions
- **Resource Group** for Terraform state storage (created automatically by setup script)

## Initial Setup

### Step 1: Configure Terraform Backend

Before deploying infrastructure, set up the Terraform backend storage. This is a one-time setup that creates the resource group, storage account, and container for storing Terraform state files.

#### Automated Setup (Recommended)

Run the provided setup script:

```bash
chmod +x setup-backend.sh
./setup-backend.sh
```

The script will:
1. Create resource group: `tfstate-rg`
2. Create storage account: `tfstatestoragein`
3. Create storage container: `tfstate`
4. Configure location: `centralindia`

## Deployment Steps

Deploy infrastructure in the following order to ensure proper dependency resolution:

### Step 1: Deploy Connectivity Layer (VNet and Subnets)

Creates the Virtual Network, subnets, and network infrastructure.

```bash
cd tf/environments/prod/landing-zones/connectivity
terraform init
terraform plan
terraform apply
```

**Resources Created:**
- Virtual Network: `vnet-prod-connectivity` (10.0.0.0/16)
- Public Subnet: 10.0.1.0/24
- Private Subnet: 10.0.2.0/24 (VMSS subnet)
- App Gateway Subnet: 10.0.3.0/24
- Service Endpoints: Microsoft.Sql, Microsoft.KeyVault

**Outputs:**
- VNet ID
- Subnet IDs (public, private, app-gateway)
- Subnet CIDR blocks

### Step 2: Deploy Ingress Layer (Load Balancer)

Creates the Azure Load Balancer with public IP and backend pool.

```bash
cd tf/environments/prod/platforms/ingress
terraform init
terraform plan
terraform apply
```

**Resources Created:**
- Azure Load Balancer Standard SKU
- Public IP address (Static, Standard)
- Backend address pool for VMSS
- HTTP health probe on port 8000
- Load balancing rule (Port 80 → 8000)

**Output:**
- Load Balancer public IP address
- Backend pool ID (used by VMSS)

**Note**: Save the public IP address - you'll use it to access the application.

### Step 3: Deploy Quotes Application (VMSS, SQL, Key Vault)

Creates VMSS with autoscaling, SQL Database, Key Vault, and supporting resources.

```bash
cd tf/environments/prod/products/quotes
terraform init
terraform plan
terraform apply
```

**Resources Created:**
- Key Vault with auto-generated secrets
- SQL Server with Private Endpoint (no public access)
- SQL Database (Standard S2 tier)
- Virtual Machine Scale Set (VMSS) with autoscaling
- Network Security Groups with ingress rules
- Log Analytics Workspace

**VMSS Features:**
- **Automatic Application Deployment**: Each VM automatically builds and deploys the Python application using cloud-init (custom_data)
- **Automatic Load Balancer Integration**: All VMSS instances (including new ones from autoscaling) are automatically added to the Load Balancer backend pool
- **Health Probes**: Load Balancer monitors VM health and routes traffic only to healthy instances
- **Auto-scaling**: Automatically scales based on CPU usage (2-10 instances)

**Outputs:**
- VMSS ID
- VMSS Name
- SQL Server FQDN
- SQL Database Name

## Automated Application Deployment

The application is **fully automated** using cloud-init. Every VM instance automatically:

1. **Installs Dependencies**: Python 3, pip, ODBC Driver 18 for SQL Server
2. **Deploys Application**: Copies application files to `/opt/quotes-app/`
3. **Initializes Database**: Runs SQL initialization script
4. **Starts Service**: Creates and starts systemd service (`quotes-app`)
5. **Health Monitoring**: Application runs on port 8000, monitored by Load Balancer

### Application Details

- **Framework**: FastAPI 0.104.1
- **Server**: Uvicorn 0.24.0
- **Port**: 8000
- **Endpoint**: `GET /` - Returns random quote from database
- **Database**: Azure SQL Database via pyodbc
- **Service**: Systemd service with auto-restart on failure

### Cloud-init Configuration

The cloud-init script (`cloud-init.yaml`) is automatically:
- Base64-encoded and injected into VMSS via `custom_data`
- Executed on every VM instance during boot
- Logged to `/var/log/cloud-init-output.log` and `/var/log/quotes-app-setup.log`

## Accessing the Application

### Via Load Balancer Public IP

Once deployment is complete, access the application using the Load Balancer public IP:

```bash
# Get Load Balancer public IP
cd tf/environments/prod/platforms/ingress
terraform output public_ip_address

# Test the application
curl http://<load-balancer-ip>/
```

**Expected Response:**
```json
{"quote": "The only way to do great work is to love what you do."}
```

### Retrieve Credentials (If Needed)

All credentials are stored in Azure Key Vault:

```bash
# Get Key Vault name
az keyvault list --resource-group tfstate-rg --query "[?contains(name, 'kv-prod-secrets')].name" -o tsv

# Get VM admin password
az keyvault secret show \
  --vault-name <key-vault-name> \
  --name vm-admin-password \
  --query value -o tsv

# Get SQL admin password
az keyvault secret show \
  --vault-name <key-vault-name> \
  --name sql-admin-password \
  --query value -o tsv
```

**Default Credentials:**
- **VM Username**: `azureadmin` (from `terraform.tfvars`)
- **SQL Login**: `sqladmin` (from `terraform.tfvars`)
- **Passwords**: Auto-generated, stored in Key Vault

## Configuration

### Variable Files (terraform.tfvars)

All configuration values are externalized in `terraform.tfvars` files:

#### Connectivity Layer (`tf/environments/prod/landing-zones/connectivity/terraform.tfvars`)

```hcl
location                = "centralindia"
vnet_address_space      = "10.0.0.0/16"
public_subnet_cidr      = "10.0.1.0/24"
private_subnet_cidr     = "10.0.2.0/24"
app_gateway_subnet_cidr = "10.0.3.0/24"
```

#### Ingress Layer (`tf/environments/prod/platforms/ingress/terraform.tfvars`)

```hcl
location  = "centralindia"
lb_zones  = [1, 2, 3]  # Availability zones for Load Balancer
```

#### Products Layer (`tf/environments/prod/products/quotes/terraform.tfvars`)

```hcl
location          = "centralindia"
vm_size           = "Standard_D2s_v3"  # 2 vCPU, 8GB RAM
vm_admin_username = "azureadmin"
sql_server_name   = "sql-prod-quotes"
sql_database_name = "quotesdb"
sql_admin_login   = "sqladmin"

# High Availability Configuration
vm_os_disk_storage_account_type = "Premium_LRS"

# VMSS Autoscaling Configuration
vmss_initial_instance_count          = 2  # HA: 2 instances minimum
vmss_zones                           = []  # No zones - Azure places VMs automatically
vmss_autoscaling_enabled             = true
vmss_autoscale_min_capacity          = 2  # HA: maintain 2 instances minimum
vmss_autoscale_max_capacity          = 10  # Scale up to 10 for high load
vmss_autoscale_cpu_threshold_scale_out = 70
vmss_autoscale_cpu_threshold_scale_in  = 30

# SQL Database Configuration
sql_database_sku_name            = "S2"
sql_database_max_size_gb         = 50
sql_zone_redundant               = false
sql_read_scale_enabled           = false
sql_geo_backup_enabled           = true
sql_short_term_retention_days    = 7

# PII Protection Configuration
key_vault_allowed_ips = ["<your-ip>"]  # Add your IP for Terraform access
sql_audit_retention_days = 90
sql_threat_detection_email_addresses = []  # Add email addresses for alerts
sql_threat_detection_retention_days = 90

tags = {
  Environment        = "prod"
  ManagedBy          = "Terraform"
  DataClassification = "PII"
  Compliance         = "Critical"
}
```

## High Availability Best Practices

1. **Use VMSS for Autoscaling**: VMSS automatically scales VMs based on CPU load
2. **Configure Appropriate Thresholds**: Adjust CPU thresholds based on your application's behavior
3. **Use Standard+ SQL Tier**: Standard S2+ or Premium tier for better SLA
4. **Enable VMSS Autoscaling**: Keep VMSS autoscaling enabled for automatic VM scaling based on traffic
5. **Configure Zone Redundancy**: For critical workloads, enable zone redundancy on SQL Database
6. **Monitor Health**: Use Load Balancer health probes and Azure Monitor for proactive monitoring
7. **Load Balancer Integration**: Load Balancer automatically discovers all VMSS instances and distributes traffic

### VM Autoscaling Behavior

**VMSS Autoscaling with Load Balancer**:
- VMs automatically scale based on CPU usage
- **Scale Out**: When average CPU across all VMs > 70% for 5 minutes, adds 1 VM (up to max)
- **Scale In**: When average CPU < 30% for 5 minutes, removes 1 VM (down to min)
- **Cooldown Periods**: 5 minutes for scale out, 10 minutes for scale in
- **Automatic Load Balancer Integration**: All new VMSS instances (from autoscaling) are automatically added to the Load Balancer backend pool - no manual configuration needed
- **Application Deployment**: Each new VM automatically builds and deploys the Python application via cloud-init (custom_data)
- **Health Monitoring**: Load Balancer health probes ensure only healthy VMs receive traffic
- **Zero-Downtime Scaling**: New VMs are added to the Load Balancer as soon as they're healthy

## PII (Personally Identifiable Information) Protection

This infrastructure treats all data as critical PII and implements comprehensive protection measures:

### Data Encryption
- **SQL Database TDE (Transparent Data Encryption)**: Enabled by default - all data at rest is automatically encrypted
- **TLS 1.2**: Minimum TLS version enforced for all SQL connections
- **Key Vault Encryption**: All secrets encrypted at rest with Azure Key Vault

### Network Security
- **SQL Private Endpoint**: Database accessible only within VNet (no public access)
- **No Public IPs on VMs**: All VMs in private subnet, accessible only via Load Balancer
- **NSG Rules**: Restrictive firewall rules allowing only required traffic
- **Service Endpoints**: Microsoft.Sql and Microsoft.KeyVault service endpoints for secure connectivity

### Access Control
- **Key Vault Network Restrictions**: Access restricted to VNet and specific IPs
- **Key Vault Purge Protection**: Prevents permanent deletion of secrets
- **Key Vault Soft Delete**: 90-day retention for deleted secrets
- **SQL Auditing**: Optional - requires storage account for audit logs
- **SQL Advanced Threat Protection**: Optional - detects suspicious database activities

### Compliance
- All resources tagged with `DataClassification = "PII"` and `Compliance = "Critical"`
- Audit logging available for SQL Database (optional)
- Threat detection available for SQL Database (optional)

## Monitoring and Logging

### Log Analytics Workspace
- **Workspace**: `law-prod-quotes`
- **Purpose**: Centralized logging and monitoring
- **Integration**: Can be connected to Azure Monitor, Application Insights, etc.

### Application Logs
- **Cloud-init Logs**: `/var/log/cloud-init-output.log`
- **Application Setup Log**: `/var/log/quotes-app-setup.log`
- **Systemd Service Logs**: `sudo journalctl -u quotes-app -f`

### Load Balancer Metrics
- **Health Probe Status**: Monitor backend pool health
- **Data Path Availability**: Track Load Balancer availability
- **Backend Pool Status**: View healthy/unhealthy instances

## Troubleshooting

### Application Not Responding

1. **Check Load Balancer Health Probes**:
   ```bash
   az network lb show --resource-group tfstate-rg --name lb-prod-ingress --query "probes"
   ```

2. **Check VMSS Instance Status**:
   ```bash
   az vmss list-instances --resource-group tfstate-rg --name vmss-prod-quotes
   ```

3. **Check Application Service** (via Azure VMSS Run Command):
   ```bash
   az vmss run-command invoke \
     --resource-group tfstate-rg \
     --name vmss-prod-quotes \
     --instance-id 0 \
     --command-id RunShellScript \
     --scripts "sudo systemctl status quotes-app"
   ```

4. **Check NSG Rules**: Verify ingress rules allow traffic on port 8000

### Load Balancer Health Probe Failing

1. **Verify VM Service is Running**: Check if application is listening on port 8000
2. **Check NSG Rules**: Ensure `AllowLoadBalancerToVM` rule exists (AzureLoadBalancer service tag)
3. **Test Locally**: `curl http://localhost:8000/` from VM
4. **Verify Health Probe Path**: Should be `/` (root endpoint)

### Cannot Access Application via Load Balancer

1. **Check Public IP**: Verify Load Balancer has a public IP assigned
2. **Check NSG Rules**: Ensure `AllowInternetToVM` rule exists (allows client traffic)
3. **Check Load Balancer Rule**: Verify rule is enabled and probe is passing
4. **Check Backend Pool**: Verify VMSS instances are registered in backend pool

### VMSS Autoscaling Not Working

1. **Check Autoscale Settings**:
   ```bash
   az monitor autoscale list --resource-group tfstate-rg
   ```

2. **Verify Metrics**: Check CPU metrics in Azure Monitor
3. **Check Cooldown Periods**: Ensure cooldown periods have elapsed
4. **Verify Min/Max Capacity**: Check if instances are at min/max limits

### SQL Connection Issues

1. **Verify Private Endpoint**: Check if Private Endpoint is created and linked
2. **Check DNS Resolution**: Verify SQL FQDN resolves to private IP
3. **Check Service Endpoints**: Ensure Microsoft.Sql service endpoint is enabled on subnet
4. **Verify NSG Rules**: Check outbound rule allows port 1433

## Resource Details

### Resource Group
All resources are deployed to: `tfstate-rg`

### Key Resources
- **VNet**: `vnet-prod-connectivity` (10.0.0.0/16)
- **Load Balancer**: `lb-prod-ingress`
- **VMSS**: `vmss-prod-quotes` (Standard_D2s_v3, Central India)
- **SQL Server**: `<sql-server-name>.database.windows.net`
- **Key Vault**: `kv-prod-secrets-<random-suffix>`
- **Log Analytics**: `law-prod-quotes`

### Network Configuration
- **Public Subnet**: 10.0.1.0/24
- **Private Subnet**: 10.0.2.0/24 (VMSS subnet)
- **App Gateway Subnet**: 10.0.3.0/24

## Maintenance

### Update Application Code

1. **Update Application Files**: Modify files in `app/` directory
2. **Re-apply Terraform**: Run `terraform apply` in products/quotes directory
3. **VMSS Rolling Update**: Terraform will trigger a rolling update of VMSS instances
4. **Automatic Deployment**: New instances will automatically deploy updated application via cloud-init

### Scale VMSS Manually

```bash
az vmss scale \
  --resource-group tfstate-rg \
  --name vmss-prod-quotes \
  --new-capacity <desired-instance-count>
```

### Update Configuration

1. **Modify terraform.tfvars**: Update configuration values
2. **Run terraform plan**: Review changes
3. **Run terraform apply**: Apply changes

## Cleanup

To destroy all resources:

```bash
# Destroy in reverse order
cd tf/environments/prod/products/quotes
terraform destroy

cd ../platforms/ingress
terraform destroy

cd ../landing-zones/connectivity
terraform destroy
```

**Note**: Key Vault with purge protection enabled cannot be deleted immediately. You may need to disable purge protection first or wait for the retention period.

