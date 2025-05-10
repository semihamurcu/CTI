#!/bin/bash

# Resource instellingen
resourceGroup="S1203586"
location="westeurope"
vnetName="testVNet"
subnetName="testSubnet"
subnetPrefix="10.1.0.0/24"
vnetPrefix="10.1.0.0/16"
internalLBName="testInternalLB"
frontendIPName="testFrontend"
backendPoolName="testBackendPool"
probeName="testProbe"
lbRuleName="testLBRule"

# Stap 2: Virtual Network en Subnet aanmaken
echo "Stap 2: VNet en Subnet aanmaken..."
az network vnet create --resource-group $resourceGroup --name $vnetName \
  --address-prefix $vnetPrefix \
  --subnet-name $subnetName --subnet-prefix $subnetPrefix

# Stap 3: Interne Load Balancer aanmaken
echo "Stap 3: Interne Load Balancer aanmaken..."
az network lb create \
  --resource-group $resourceGroup \
  --name $internalLBName \
  --sku Standard \
  --frontend-ip-name $frontendIPName \
  --vnet-name $vnetName \
  --subnet $subnetName \
  --private-ip-address-version IPv4 \
  --location $location

# Belangrijk: expliciet backend pool aanmaken
az network lb address-pool create \
  --resource-group $resourceGroup \
  --lb-name $internalLBName \
  --name $backendPoolName

# Stap 4: Probe en Load Balancing rule toevoegen
echo "Stap 4: Probe en load balancing rule configureren..."
az network lb probe create \
  --resource-group $resourceGroup \
  --lb-name $internalLBName \
  --name $probeName \
  --protocol Tcp \
  --port 3306 \
  --interval 5 \
  --threshold 2

az network lb rule create \
  --resource-group $resourceGroup \
  --lb-name $internalLBName \
  --name $lbRuleName \
  --protocol Tcp \
  --frontend-port 3306 \
  --backend-port 3306 \
  --frontend-ip-name $frontendIPName \
  --backend-pool-name $backendPoolName \
  --probe-name $probeName

# Stap 5: Test backend VM's aanmaken
echo "Stap 5: Test VM's aanmaken..."
az vm create --resource-group $resourceGroup --name testVM1 --image Ubuntu2204 \
  --vnet-name $vnetName --subnet $subnetName \
  --admin-username azureuser --authentication-type ssh \
  --ssh-key-value ~/.ssh/id_rsa.pub --zone 1

az vm create --resource-group $resourceGroup --name testVM2 --image Ubuntu2204 \
  --vnet-name $vnetName --subnet $subnetName \
  --admin-username azureuser --authentication-type ssh \
  --ssh-key-value ~/.ssh/id_rsa.pub --zone 2

# Stap 6: VM NICs koppelen aan backend pool
echo "Stap 6: NICs koppelen aan backend pool..."

nic1=$(az vm show --resource-group $resourceGroup --name testVM1 --query "networkProfile.networkInterfaces[0].id" -o tsv | xargs basename)
nic2=$(az vm show --resource-group $resourceGroup --name testVM2 --query "networkProfile.networkInterfaces[0].id" -o tsv | xargs basename)

az network nic ip-config address-pool add \
  --address-pool $backendPoolName \
  --ip-config-name ipconfig1 \
  --nic-name $nic1 \
  --resource-group $resourceGroup \
  --lb-name $internalLBName

az network nic ip-config address-pool add \
  --address-pool $backendPoolName \
  --ip-config-name ipconfig1 \
  --nic-name $nic2 \
  --resource-group $resourceGroup \
  --lb-name $internalLBName

echo "Script voltooid!"
