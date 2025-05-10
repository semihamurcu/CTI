#!/bin/bash

# Stap 1: Variabelen instellen
resourceGroup="S1203586"
location="westeurope"
vnetName="myVnet"
subnetWeb="subnetWeb"
subnetDB="subnetDB"
lbName="myLoadBalancer"
publicIPName="myPublicIP"
frontendIPConfig="myFrontendIP"
backendPoolName="myBackendPool"
probeName="myProbe"
lbRule="myLBRule"
jumpboxName="jumpboxVM"
vmssName="webVMSS"
vmssSku="Standard_DS2_v2"
vmssCapacity="2"

# Step 2: Create Virtual Network and Subnets
az network vnet create --resource-group $resourceGroup --name $vnetName --address-prefix 10.0.0.0/16 --subnet-name $subnetWeb --subnet-prefix 10.0.1.0/24
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $subnetDB --address-prefix 10.0.2.0/24

# Step 3: Create Load Balancer
az network public-ip create --resource-group $resourceGroup --name $publicIPName --allocation-method Static --sku Standard --location $location
az network lb create --resource-group $resourceGroup --name $lbName --sku Standard --frontend-ip-name $frontendIPConfig --public-ip-address $publicIPName

# Step 4: Create Backend Pool and Health Probe for Load Balancer
az network lb address-pool create --resource-group $resourceGroup --lb-name $lbName --name $backendPoolName
az network lb probe create --resource-group $resourceGroup --lb-name $lbName --name $probeName --protocol Tcp --port 80 --interval 5 --threshold 2

# Step 5: Create Load Balancer Rule
az network lb rule create --resource-group $resourceGroup --lb-name $lbName --name $lbRule --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $frontendIPConfig --backend-address-pool $backendPoolName --probe-name $probeName

# Step 6: Create Jumpbox VM (Ubuntu) in Zone 1
az vm create --resource-group $resourceGroup --name $jumpboxName --image Ubuntu2204 --vnet-name $vnetName --subnet $subnetWeb --admin-username azureuser --authentication-type ssh --ssh-key-value ~/.ssh/id_rsa.pub --zone 1

# Step 7: Create Web VM Scale Set in Zone 1
az vmss create --resource-group $resourceGroup --name $vmssName --image Ubuntu2204 --upgrade-policy-mode automatic --admin-username azureuser --ssh-key-value ~/.ssh/id_rsa.pub --zones 1  # Zone 1

# Step 8: Create Database 1 in Zone 1
az mysql server create --resource-group $resourceGroup --name db1-server --location $location --sku-name B_Gen5_1 --admin-user azureuser --admin-password 'password123' --vnet-name $vnetName --subnet $subnetDB --zone 1

# Step 9: Create Database 2 in Zone 2
az mysql server create --resource-group $resourceGroup --name db2-server --location $location --sku-name B_Gen5_1 --admin-user azureuser --admin-password 'password123' --vnet-name $vnetName --subnet $subnetDB --zone 2

# Step 10: Output the IP address of the Load Balancer
lbIP=$(az network public-ip show --resource-group $resourceGroup --name $publicIPName --query "ipAddress" --output tsv)
echo "De Load Balancer is ingesteld en heeft het IP adres: $lbIP"
echo "De Jumpbox VM is ingesteld op Zone 1"
echo "De VMSS is ingesteld in Zone 1"
echo "De Database 1 is ingesteld in Zone 1"
echo "De Database 2 is ingesteld in Zone 2"
