#!/bin/bash

# 🔧 Variabelen
resourceGroup="S1203586"
location="westeurope"
vnetName="ssc-vnet"
subnetWeb="subnet-web"
subnetDB="subnet-db"
subnetMgmt="subnet-management"
nsgWeb="nsg-web"
nsgDB="nsg-db"
nsgMgmt="nsg-management"
lbName="ssc-lb"
publicIP="ssc-public-ip"
frontendIP="ssc-frontend-ip"
backendPool="ssc-backend-pool"
probe="http-probe"
lbRule="http-rule"
vmssName="web-vmss"
jumpboxName="jumpbox"

# 📦 VNET en Subnets
az network vnet create --resource-group $resourceGroup --location $location \
  --name $vnetName \
  --address-prefix 10.0.0.0/16 \
  --subnet-name $subnetWeb --subnet-prefix 10.0.1.0/24

az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName \
  --name $subnetDB --address-prefix 10.0.2.0/24

az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName \
  --name $subnetMgmt --address-prefix 10.0.3.0/24

# 🔐 NSG's en regels
for subnet in $nsgWeb $nsgDB $nsgMgmt; do
  az network nsg create --resource-group $resourceGroup --name $subnet
done

az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgWeb \
  --name AllowHTTP --priority 1000 --direction Inbound --access Allow --protocol Tcp \
  --
