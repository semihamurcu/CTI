#!/bin/bash

RESOURCE_GROUP="S1203586"
LOCATION="westeurope"
NSG_NAME="nsg-coevorden"
VM_NAME="vm-coevorden"
VNET_NAME="vnet-coevorden"
SUBNET_NAME="subnet-coevorden"
NIC_NAME="nic-$VM_NAME"
ADMIN_USERNAME="azureuser"
ADMIN_PASSWORD="ComplexP@ssw0rd123!"  # Pas dit aan naar een veilig wachtwoord

# 1. Maak NSG aan of check of bestaat
az network nsg show --resource-group $RESOURCE_GROUP --name $NSG_NAME >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating NSG $NSG_NAME..."
  az network nsg create --resource-group $RESOURCE_GROUP --location $LOCATION --name $NSG_NAME
else
  echo "NSG $NSG_NAME already exists"
fi

# Voeg firewall regels toe
az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name AllowRDPMyIP \
  --protocol Tcp --direction Inbound --source-address-prefixes 145.44.234.65 --destination-port-ranges 3389 \
  --access Allow --priority 100 --description "Allow RDP from my own IP only" --output none

az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name DenyRDPOthers \
  --protocol Tcp --direction Inbound --source-address-prefixes '*' --destination-port-ranges 3389 \
  --access Deny --priority 110 --description "Deny RDP from all other IPs" --output none

# 2. Maak virtueel netwerk en subnet als ze nog niet bestaan
az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating virtual network $VNET_NAME..."
  az network vnet create --resource-group $RESOURCE_GROUP --location $LOCATION --name $VNET_NAME --address-prefix 10.0.0.0/16 --subnet-name $SUBNET_NAME --subnet-prefix 10.0.1.0/24
else
  echo "Virtual network $VNET_NAME already exists"
fi

# 3. Maak netwerkinterface aan en koppel de NSG eraan
az network nic create --resource-group $RESOURCE_GROUP --name $NIC_NAME --vnet-name $VNET_NAME --subnet $SUBNET_NAME --network-security-group $NSG_NAME

# 4. Maak VM aan, met admin user en password (geen public IP)
az vm show --resource-group $RESOURCE_GROUP --name $VM_NAME >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating VM $VM_NAME..."
  az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --location $LOCATION \
    --nics $NIC_NAME \
    --image Ubuntu2204 \
    --admin-username $ADMIN_USERNAME \
    --admin-password $ADMIN_PASSWORD \
    --authentication-type password \
    --public-ip-address "" \
    --no-wait
else
  echo "VM $VM_NAME already exists"
fi

echo "Setup complete. VM '$VM_NAME' is created with NSG '$NSG_NAME' restricting RDP access to IP 145.44.234.65 only."
