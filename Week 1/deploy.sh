#!/bin/bash

# Variabelen
resourceGroup="S1203586"
location="West Europe"
vnetName="myVnet"
subnetWeb="subnetWeb"
subnetDB="subnetDB"
subnetMgmt="subnetMgmt"
nsgWeb="NSGWeb"
nsgMgmt="NSGMgmt"
lbName="myLoadBalancer"
publicIPName="myPublicIP"
frontendIPConfig="myFrontendIP"
backendPoolName="myBackendPool"
probeName="myProbe"
lbRule="myLBRule"
jumpboxName="JumpboxVM"
vmssName="WebVMSS"

# Resourcegroep controleren (bestaat al, dus geen create)

# VNET en subnets
az network vnet create --resource-group $resourceGroup --name $vnetName --address-prefix 10.0.0.0/16 \
  --subnet-name $subnetWeb --subnet-prefix 10.0.1.0/24

az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $subnetDB --address-prefix 10.0.2.0/24
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $subnetMgmt --address-prefix 10.0.3.0/24

# NSG's
az network nsg create --resource-group $resourceGroup --name $nsgWeb
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgWeb --name AllowHTTP \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' --source-port-range '*' \
  --destination-address-prefix '*' --destination-port-range 80 --access allow

az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetWeb --network-security-group $nsgWeb

az network nsg create --resource-group $resourceGroup --name $nsgMgmt
az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgMgmt --name AllowSSH \
  --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' --source-port-range '*' \
  --destination-address-prefix '*' --destination-port-range 22 --access allow

az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetMgmt --network-security-group $nsgMgmt

# Public IP voor Load Balancer
az network public-ip create --resource-group $resourceGroup --name $publicIPName --allocation-method Static --sku Standard --location "$location"

# Load Balancer
az network lb create --resource-group $resourceGroup --name $lbName --sku Standard \
  --frontend-ip-name $frontendIPConfig --public-ip-address $publicIPName --location "$location"

az network lb address-pool create --resource-group $resourceGroup --lb-name $lbName --name $backendPoolName

az network lb probe create --resource-group $resourceGroup --lb-name $lbName --name $probeName \
  --protocol Tcp --port 80 --interval 5 --threshold 2

az network lb rule create --resource-group $resourceGroup --lb-name $lbName --name $lbRule \
  --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $frontendIPConfig \
  --backend-address-pool-name $backendPoolName --probe-name $probeName

# VM Scale Set voor Weblaag
az vmss create \
  --resource-group $resourceGroup \
  --name $vmssName \
  --image UbuntuLTS \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --generate-ssh-keys \
  --vnet-name $vnetName \
  --subnet $subnetWeb \
  --backend-pool-name $backendPoolName \
  --lb $lbName \
  --instance-count 2 \
  --load-balancer-sku Standard \
  --vm-sku Standard_B1s \
  --custom-data cloud-init.txt

# Jumpbox VM
az vm create \
  --resource-group $resourceGroup \
  --name $jumpboxName \
  --image UbuntuLTS \
  --vnet-name $vnetName \
  --subnet $subnetMgmt \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# Load Balancer IP ophalen
lbIP=$(az network public-ip show --resource-group $resourceGroup --name $publicIPName --query "ipAddress" --output tsv)

echo "✅ Load Balancer IP: $lbIP"
