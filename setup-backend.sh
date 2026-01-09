#!/bin/bash
# Setup script for Terraform backend infrastructure
# This script creates the resource group, storage account, and container for Terraform state

set -e

RESOURCE_GROUP="tfstate-rg"
STORAGE_ACCOUNT="tfstatestoragein"
CONTAINER="tfstate"
LOCATION="centralindia"

echo "Setting up Terraform backend infrastructure..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Location: $LOCATION"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" || {
    echo "Warning: Resource group may already exist. Continuing..."
}

# Create storage account
echo "Creating storage account: $STORAGE_ACCOUNT..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS || {
    echo "Warning: Storage account may already exist. Continuing..."
}

# Create storage container (using Azure login authentication)
echo "Creating storage container: $CONTAINER..."
az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login || {
    echo "Warning: Container may already exist. Continuing..."
}

echo ""
echo " Terraform backend setup completed successfully!"
echo ""
echo "Backend Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Container: $CONTAINER"
echo ""
echo "You can now proceed with Terraform deployments."
