#!/bin/bash

# Azure Infrastructure Deployment Script
# This script deploys all infrastructure layers in the correct order:
# 1. Connectivity Layer (VNet, Subnets)
# 2. Ingress Layer (Load Balancer)
# 3. Products Layer (VMSS, SQL, Key Vault)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR"

# Terraform directories
CONNECTIVITY_DIR="$BASE_DIR/tf/environments/prod/landing-zones/connectivity"
INGRESS_DIR="$BASE_DIR/tf/environments/prod/platforms/ingress"
PRODUCTS_DIR="$BASE_DIR/tf/environments/prod/products/quotes"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to setup Terraform backend
setup_backend() {
    print_info "Checking Terraform backend setup..."
    
    local RESOURCE_GROUP="tfstate-rg"
    local STORAGE_ACCOUNT="tfstatestoragein"
    local CONTAINER="tfstate"
    local LOCATION="centralindia"
    
    # Check if resource group exists, create if not
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating resource group: $RESOURCE_GROUP..."
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
        print_success "Resource group created"
    else
        print_info "Resource group exists: $RESOURCE_GROUP"
    fi
    
    # Check if storage account exists, create if not
    if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating storage account: $STORAGE_ACCOUNT..."
        az storage account create \
            --name "$STORAGE_ACCOUNT" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku Standard_LRS
        print_success "Storage account created"
    else
        print_info "Storage account exists: $STORAGE_ACCOUNT"
    fi
    
    # Check if container exists, create if not
    if ! az storage container show --name "$CONTAINER" --account-name "$STORAGE_ACCOUNT" --auth-mode login &> /dev/null; then
        print_info "Creating storage container: $CONTAINER..."
        az storage container create \
            --name "$CONTAINER" \
            --account-name "$STORAGE_ACCOUNT" \
            --auth-mode login
        print_success "Storage container created"
    else
        print_info "Storage container exists: $CONTAINER"
    fi
    
    print_success "Terraform backend is ready"
}

# Function to run Terraform commands
run_terraform() {
    local dir=$1
    local layer_name=$2
    
    print_info "Deploying $layer_name..."
    print_info "Directory: $dir"
    
    if [ ! -d "$dir" ]; then
        print_error "Directory not found: $dir"
        return 1
    fi
    
    cd "$dir"
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    if ! terraform init; then
        print_error "Terraform init failed for $layer_name"
        return 1
    fi
    
    # Plan
    print_info "Running Terraform plan..."
    if ! terraform plan -out=tfplan; then
        print_error "Terraform plan failed for $layer_name"
        return 1
    fi
    
    # Apply
    print_info "Applying Terraform configuration..."
    print_warning "This will create/modify Azure resources. Press Ctrl+C to cancel within 5 seconds..."
    sleep 5
    
    if ! terraform apply -auto-approve tfplan; then
        print_error "Terraform apply failed for $layer_name"
        return 1
    fi
    
    # Clean up plan file
    rm -f tfplan
    
    print_success "$layer_name deployment completed"
    return 0
}

# Function to wait for Load Balancer backend pool to be ready
wait_for_load_balancer() {
    print_info "Waiting for Load Balancer backend pool to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local lb_exists=$(az network lb list --resource-group tfstate-rg --query "[?name=='lb-prod-ingress'] | length(@)" -o tsv 2>/dev/null || echo "0")
        
        if [ "$lb_exists" -gt 0 ]; then
            print_success "Load Balancer is ready"
            return 0
        fi
        
        print_info "Waiting for Load Balancer... (attempt $attempt/$max_attempts)"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    print_warning "Load Balancer check timeout, but continuing..."
    return 0
}

# Function to wait for VMSS instances to register with Load Balancer
wait_for_vmss_registration() {
    print_info "Waiting for VMSS instances to register with Load Balancer..."
    
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local backend_addresses=$(az network lb show \
            --resource-group tfstate-rg \
            --name lb-prod-ingress \
            --query "backendAddressPools[0].loadBalancerBackendAddresses | length(@)" \
            -o tsv 2>/dev/null || echo "0")
        
        if [ "$backend_addresses" -ge 2 ]; then
            print_success "VMSS instances registered with Load Balancer (count: $backend_addresses)"
            return 0
        fi
        
        print_info "Waiting for VMSS registration... (attempt $attempt/$max_attempts, found: $backend_addresses)"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    print_warning "VMSS registration check timeout, but deployment completed"
    return 0
}

# Function to display deployment summary
show_summary() {
    print_info "Deployment Summary"
    echo "=================================="
    
    # Get Load Balancer Public IP
    local public_ip=$(az network public-ip show \
        --resource-group tfstate-rg \
        --name lb-prod-ingress-pip \
        --query "ipAddress" -o tsv 2>/dev/null || echo "N/A")
    
    if [ "$public_ip" != "N/A" ]; then
        print_success "Load Balancer Public IP: $public_ip"
        echo ""
        print_info "Test the application with:"
        echo "  curl http://$public_ip/"
    fi
    
    # Get VMSS instance count
    local vmss_instances=$(az vmss list-instances \
        --resource-group tfstate-rg \
        --name vmss-prod-quotes \
        --query "length(@)" -o tsv 2>/dev/null || echo "0")
    
    if [ "$vmss_instances" -gt 0 ]; then
        print_success "VMSS Instances: $vmss_instances"
    fi
    
    # Get SQL Server FQDN
    local sql_fqdn=$(az sql server show \
        --resource-group tfstate-rg \
        --name sql-prod-quotes \
        --query "fullyQualifiedDomainName" -o tsv 2>/dev/null || echo "N/A")
    
    if [ "$sql_fqdn" != "N/A" ]; then
        print_success "SQL Server: $sql_fqdn"
    fi
    
    echo ""
    print_success "Deployment completed successfully!"
}

# Main deployment function
main() {
    echo "=================================="
    echo "Azure Infrastructure Deployment"
    echo "=================================="
    echo ""
    
    # Check prerequisites
    check_prerequisites
    echo ""
    
    # Setup Terraform backend
    setup_backend
    echo ""
    
    # Step 1: Deploy Connectivity Layer
    echo "=================================="
    echo "Step 1/3: Connectivity Layer"
    echo "=================================="
    if ! run_terraform "$CONNECTIVITY_DIR" "Connectivity Layer"; then
        print_error "Connectivity Layer deployment failed"
        exit 1
    fi
    echo ""
    
    # Step 2: Deploy Ingress Layer
    echo "=================================="
    echo "Step 2/3: Ingress Layer (Load Balancer)"
    echo "=================================="
    if ! run_terraform "$INGRESS_DIR" "Ingress Layer"; then
        print_error "Ingress Layer deployment failed"
        exit 1
    fi
    
    # Wait for Load Balancer to be ready
    wait_for_load_balancer
    echo ""
    
    # Step 3: Deploy Products Layer
    echo "=================================="
    echo "Step 3/3: Products Layer (VMSS, SQL, Key Vault)"
    echo "=================================="
    if ! run_terraform "$PRODUCTS_DIR" "Products Layer"; then
        print_error "Products Layer deployment failed"
        exit 1
    fi
    
    # Wait for VMSS instances to register with Load Balancer
    wait_for_vmss_registration
    echo ""
    
    # Show summary
    echo "=================================="
    show_summary
    echo "=================================="
}

# Run main function
main
