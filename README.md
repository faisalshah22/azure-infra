# Azure Infrastructure - Quotes Application

Terraform infrastructure for deploying a FastAPI quotes application on Microsoft Azure. This architecture implements a three-tier deployment model with network isolation, secure access via Azure Bastion, and automated secret management.

## Architecture Overview

```
Internet
  ↓
Azure Application Gateway (Public IP)
  ↓
Linux VM (Private Subnet - )
  ↓
Azure SQL Database (Private Access via VNet Rules)
```

### Components

- **Application Gateway**: Public-facing load balancer routing HTTP traffic to the VM did not added https needed a domain name for it
- **Linux VM**: Ubuntu 22.04 LTS running FastAPI application on port 8000
- **Azure SQL Database**: Managed SQL Server with quotes data
- **Azure Bastion**: Secure browser-based access to VM (no SSH keys required)
- **Key Vault**: Automated secret generation and storage for credentials
- **Network Security Groups**: Restrictive firewall rules allowing only required traffic
- **Log Analytics Workspace**: Centralized logging and monitoring

## Folder Structure

```
azure-infra/
├── app/                          # Application source code
│   ├── app.py                   # FastAPI application
│   ├── requirements.txt         # Python dependencies
│   ├── init-db.sql             # Database schema and seed data
│   ├── Dockerfile               # Multi-stage Dockerfile for containerization
│   └── .dockerignore            # Docker ignore file
│
└── tf/                          # Terraform infrastructure
    ├── modules/                 # Reusable Terraform modules
    │   ├── vpc/                 # Virtual Network and Subnets
    │   ├── nsg/                 # Network Security Groups
    │   ├── app-gateway/         # Application Gateway
    │   ├── bastion/             # Azure Bastion Host
    │   ├── vm/                  # Linux Virtual Machine
    │   ├── sql/                 # Azure SQL Database
    │   └── monitoring/          # Log Analytics Workspace
│
└── environments/
    └── prod/
        ├── landing-zones/
            │   └── connectivity/    # VNet, Subnets, Bastion
        ├── platforms/
            │   └── ingress/         # Application Gateway
        └── products/
                └── quotes/          # VM, SQL, NSGs, Monitoring
```

## Deployment Architecture

### Three-Tier Deployment Model

1. **Landing Zones (Connectivity)**
   - Virtual Network with address space:
   - Subnets: Public, Private, App Gateway, Bastion
   - Azure Bastion for secure VM access
   - Microsoft.Sql service endpoint on private subnet

2. **Platforms (Ingress)**
   - Application Gateway Standard_v2
   - Public IP for internet access
   - Health probes and routing rules
   - SSL/TLS policy configuration

3. **Products (Quotes Application)**
   - Linux VM (Standard_D2s_v3) in private subnet
   - Azure SQL Database with VNet rules
   - Network Security Groups
   - Key Vault for credential management
   - Log Analytics Workspace

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.0
- Azure subscription with contributor permissions
- Resource group `tfstate-rg` created manually
- Storage account `tfstatestoragein` for Terraform state

## Configuration

### Backend Configuration

All Terraform states are stored in Azure Storage Account:

- **Storage Account**: `tfstatestoragein`
- **Resource Group**: `tfstate-rg`
- **Container**: `tfstate`

Backend configuration is defined in `backend.tf` files in each environment layer.

### Variables Configuration

Edit `tf/environments/prod/products/quotes/terraform.tfvars`:

```hcl
location          = "centralindia"
vm_size           = "Standard_D2s_v3"
vm_admin_username = "azureadmin"
sql_server_name   = "sql-prod-quotes"
sql_database_name = "quotesdb"
sql_admin_login   = "sqladmin"
```

## Deployment Steps

### Step 1: Deploy Connectivity Layer

Creates the network foundation including VNet, subnets, and Bastion.

```bash
cd tf/environments/prod/landing-zones/connectivity
terraform init
terraform plan
terraform apply
```

**Outputs:**
- VNet ID and address space
- Subnet IDs (public, private, app-gateway, bastion)
- Bastion host details

### Step 2: Deploy Quotes Application

Creates VM, SQL Database, Key Vault, and supporting resources.

```bash
cd tf/environments/prod/products/quotes
terraform init
terraform plan
terraform apply
```

**Resources Created:**
- Key Vault with auto-generated secrets
- SQL Server with VNet rules
- Linux VM with dynamic IP allocation
- Network Security Groups
- Log Analytics Workspace

**Outputs:**
- VM private IP address
- SQL Server FQDN
- VM ID

### Step 3: Deploy Ingress Layer

Creates Application Gateway that routes traffic to the VM.

```bash
cd tf/environments/prod/platforms/ingress
terraform init
terraform plan
terraform apply
```

**Resources Created:**
- Application Gateway Standard_v2
- Public IP address
- Health probes and routing rules

**Output:**
- Application Gateway public IP: `135.235.173.95`

## Manual Application Deployment

Due to Azure Bastion Basic tier limitations, the application code was manually deployed to the VM. The cloud-init script is configured but requires manual intervention for complete setup.

### Access VM via Azure Bastion

1. Navigate to Azure Portal → Virtual Machines
2. Select `vm-prod-quotes`
3. Click "Bastion" in the left menu
4. Enter credentials:
   - **Username**: `azureadmin`
   - **Password**: Retrieve from Key Vault (see below)

### Retrieve Credentials from Key Vault

```bash
# Get Key Vault name
az keyvault list --resource-group tfstate-rg --query "[?contains(name, 'kv-prod-secrets')].name" -o tsv

# Get VM password
az keyvault secret show --vault-name <key-vault-name> --name vm-admin-password --query "value" -o tsv

# Get SQL credentials
az keyvault secret show --vault-name <key-vault-name> --name sql-admin-password --query "value" -o tsv
```

### Manual Application Setup on VM beacuse i have setup the basic bastion avoided ssh key based acces due to security reasons

Once connected via Bastion, execute the following commands:

```bash
# Create application directory
sudo mkdir -p /opt/quotes-app
cd /opt/quotes-app

# Create requirements.txt
sudo tee requirements.txt > /dev/null <<'EOF'
fastapi==0.104.1
uvicorn==0.24.0
pyodbc==5.0.1
EOF

# Create app.py
sudo tee app.py > /dev/null <<'EOF'
from fastapi import FastAPI
import pyodbc
import os

app = FastAPI()

@app.get("/")
async def get_quote():
    try:
        server = os.environ.get("SQL_SERVER")
        database = os.environ.get("SQL_DATABASE")
        username = os.environ.get("SQL_USER")
        password = os.environ.get("SQL_PASSWORD")
        
        conn_str = f"Driver={{ODBC Driver 18 for SQL Server}};Server=tcp:{server},1433;Database={database};Uid={username};Pwd={password};Encrypt=yes;TrustServerCertificate=yes;Connection Timeout=30;"
        
        conn = pyodbc.connect(conn_str)
        query = conn.execute("SELECT TOP 1 quote FROM quotes ORDER BY NEWID()")
        row = query.fetchone()
        
        conn.close()
        
        if row:
            return {"quote": row[0]}
        else:
            return {"quote": "No quotes available"}
    except Exception as e:
        return {"error": str(e)}
EOF

# Install Python packages
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install -r requirements.txt

# Install SQL Server tools
curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18
export PATH="$PATH:/opt/mssql-tools18/bin"

# Initialize database
sqlcmd -S <sql-server-name>.database.windows.net -U sqladmin -P '<password-from-keyvault>' -d quotesdb -i init-db.sql

# Create init-db.sql
sudo tee init-db.sql > /dev/null <<'EOF'
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[quotes]') AND type in (N'U'))
BEGIN
    CREATE TABLE quotes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        quote NVARCHAR(MAX) NOT NULL
    );
    
    INSERT INTO quotes (quote) VALUES
    ('The only way to do great work is to love what you do.'),
    ('Innovation distinguishes between a leader and a follower.'),
    ('Life is what happens to you while you''re busy making other plans.'),
    ('The future belongs to those who believe in the beauty of their dreams.'),
    ('It is during our darkest moments that we must focus to see the light.');
END
EOF

# Create systemd service
sudo tee /etc/systemd/system/quotes-app.service > /dev/null <<'EOF'
[Unit]
Description=Quotes FastAPI App
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/quotes-app
Environment="SQL_SERVER=<sql-server-name>.database.windows.net"
Environment="SQL_DATABASE=quotesdb"
Environment="SQL_USER=sqladmin"
Environment="SQL_PASSWORD=<password-from-keyvault>"
ExecStart=/usr/bin/python3 -m uvicorn app:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable quotes-app
sudo systemctl start quotes-app
sudo systemctl status quotes-app
```

## Docker Deployment

The application includes a multi-stage Dockerfile for containerized deployment. This enables easy deployment to container orchestration platforms like Azure Kubernetes Service (AKS).

### Dockerfile Overview

The multi-stage Dockerfile (`app/Dockerfile`) consists of two stages:

1. **Builder Stage**: Installs build dependencies, ODBC drivers, and Python packages
2. **Runtime Stage**: Creates a minimal image with only runtime dependencies

### Building the Docker Image

```bash
cd app
docker build -t quotes-app:latest .
```

### Running the Container Locally

```bash
docker run -d \
  --name quotes-app \
  -p 8000:8000 \
  -e SQL_SERVER=<sql-server-name>.database.windows.net \
  -e SQL_DATABASE=quotesdb \
  -e SQL_USER=sqladmin \
  -e SQL_PASSWORD=<password-from-keyvault> \
  quotes-app:latest
```

### Testing the Containerized Application

```bash
curl http://localhost:8000/
```

### Docker Image Optimization

The multi-stage build reduces the final image size by:
- Separating build-time and runtime dependencies
- Removing build tools from the final image
- Using Python slim base image
- Cleaning up package manager cache

### Pushing to Azure Container Registry

```bash
# Login to Azure Container Registry
az acr login --name <your-acr-name>

# Tag the image
docker tag quotes-app:latest <your-acr-name>.azurecr.io/quotes-app:latest

# Push the image
docker push <your-acr-name>.azurecr.io/quotes-app:latest
```

## Security Architecture

### Network Security

- **VM**: No public IP, accessible only via Bastion or from App Gateway subnet
- **SQL Database**: accessible only via VNet rules within the VPC
- **Application Gateway**: Public IP with Standard SKU
- **NSG Rules**:
  - Allow App Gateway subnet → VM on port 8000
  - Allow VM → SQL on port 1433
  - Deny all other traffic

### Secret Management

All credentials are automatically generated and stored in Azure Key Vault:

- **VM Admin Password**: 16-character random password
- **SQL Admin Password**: 16-character random password
- **VM Admin Username**: Configurable (default: `azureadmin`)
- **SQL Admin Login**: Configurable (default: `sqladmin`)

Key Vault is created automatically in the `tfstate-rg` resource group with appropriate access policies.

### Access Control

- **Azure Bastion**: Browser-based secure access without SSH keys
- **No Public IPs**: VM and SQL are in private subnets
- **VNet Rules**: SQL access restricted to private subnet only
- **Service Endpoints**: Microsoft.Sql endpoint configured on private subnet

## Application Details

### FastAPI Application

- **Framework**: FastAPI 0.104.1
- **Server**: Uvicorn 0.24.0
- **Port**: 8000
- **Endpoint**: `GET /`
- **Database**: Azure SQL Database via pyodbc

### Database Schema

```sql
CREATE TABLE quotes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    quote NVARCHAR(MAX) NOT NULL
);
```

Initial seed data includes 5 inspirational quotes.

## Testing

### Test Application Locally on VM

```bash
curl http://localhost:8000/
```

Expected response:
```json
{"quote": "The only way to do great work is to love what you do."}
```

### Test via Application Gateway

```bash
curl http://load_balancer_public_ip/
```

### Application Response Screenshot

The application successfully returns random quotes from the database when accessed via the Application Gateway:

![Application Response](screenshot.png)

The JSON response displays a random quote from the database, confirming the end-to-end connectivity from the Application Gateway through the VM to the SQL Database.

### Check Service Status

```bash
sudo systemctl status quotes-app
sudo journalctl -u quotes-app -f
```

## Resource Details

### Resource Group

All resources are deployed to: `tfstate-rg`

### Key Resources

- **VNet**: `vnet-prod-connectivity` (10.0.0.0/16)
- **VM**: `vm-prod-quotes` (Standard_D2s_v3, Central India)
- **SQL Server**: `<sql-server-name>.database.windows.net`
- **Application Gateway**: `agw-prod-ingress`
- **Key Vault**: `kv-prod-secrets-<random-suffix>`
- **Bastion**: `bastion-prod-connectivity`

### Network Configuration

- **Public Subnet**: 10.0.1.0/24
- **Private Subnet**: 10.0.2.0/24 (VM subnet)
- **App Gateway Subnet**: 10.0.3.0/24
- **Bastion Subnet**: 10.0.4.0/26

## Troubleshooting

### Application Not Responding

1. Check service status: `sudo systemctl status quotes-app`
2. Check logs: `sudo journalctl -u quotes-app -n 50`
3. Verify SQL connectivity from VM
4. Check NSG rules allow App Gateway → VM traffic

### Cannot Access VM via Bastion

1. Verify Bastion is deployed and running
2. Check VM is in the same VNet as Bastion
3. Verify credentials from Key Vault

### Application Gateway Health Probe Failing

1. Verify VM service is running on port 8000
2. Check NSG allows traffic from App Gateway subnet
3. Test locally: `curl http://localhost:8000/`

## Maintenance

### Update Application Code

1. Connect to VM via Bastion
2. Edit files in `/opt/quotes-app/`
3. Restart service: `sudo systemctl restart quotes-app`

### Rotate Credentials

Credentials are stored in Key Vault. To rotate:

1. Generate new secrets in Key Vault
2. Update service environment variables
3. Restart application service

### View Logs

```bash
# Application logs
sudo journalctl -u quotes-app -f

# Cloud-init logs
sudo cat /var/log/cloud-init-output.log
```

## Cost Optimization

- **VM**: Standard_D2s_v3 (2 vCPU, 8GB RAM) this vm was used because small vm's where not available - can be scaled down 
- **SQL Database**: Basic tier (2GB max)
- **Application Gateway**: Standard_v2 with capacity 1
- **Bastion**: Basic tier (manual code deployment required)

## Future Enhancements

- Automate application deployment via custom script extension
- Implement CI/CD pipeline for code updates
- Add monitoring alerts and dashboards
- Scale to multiple VMs with load balancing
- Implement private endpoints for SQL Database
- Add SSL/TLS certificates to Application Gateway
- **Deploy to Azure Kubernetes Service (AKS)**: 
  - Use the provided multi-stage Dockerfile to containerize the application
  - Deploy to AKS cluster with proper networking and security configurations
  - Implement horizontal pod autoscaling based on CPU/memory metrics
  - Use Azure Container Registry (ACR) for image storage
  - Configure Azure SQL Database connection pooling for Kubernetes pods
  - Implement Kubernetes secrets for SQL credentials management
  - Use Azure Load Balancer or Application Gateway Ingress Controller for traffic routing
  - Enable Azure Monitor / grafana stack for Containers for observability

