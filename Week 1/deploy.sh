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

# Stap 2: VNET en subnets maken
az network vnet create --resource-group $resourceGroup --name $vnetName --address-prefix 10.0.0.0/16 --subnet-name $subnetWeb --subnet-prefix 10.0.1.0/24
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $subnetDB --address-prefix 10.0.2.0/24

# Stap 3: Public IP maken voor Load Balancer
az network public-ip create --resource-group $resourceGroup --name $publicIPName --allocation-method Static --sku Standard --location $location

# Stap 4: Load Balancer aanmaken
az network lb create --resource-group $resourceGroup --name $lbName --sku Standard --frontend-ip-name $frontendIPConfig --public-ip-address $publicIPName --location $location

# Stap 5: Backend pool aanmaken
az network lb address-pool create --resource-group $resourceGroup --lb-name $lbName --name $backendPoolName

# Stap 6: Health probe configureren
az network lb probe create --resource-group $resourceGroup --lb-name $lbName --name $probeName --protocol Tcp --port 80 --interval 5 --threshold 2

# Stap 7: Load balancer rule instellen
az network lb rule create --resource-group $resourceGroup --lb-name $lbName --name $lbRule --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $frontendIPConfig --backend-pool-name $backendPoolName --probe-name $probeName

# Stap 8: Jumpbox VM aanmaken met ubuntu image
az vm create --resource-group $resourceGroup --name $jumpboxName --image Ubuntu2204 --vnet-name $vnetName --subnet $subnetWeb --admin-username azureuser --generate-ssh-keys --location $location

# Stap 9: VM Scale Set aanmaken met ubuntu image
az vmss create --resource-group $resourceGroup --name $vmssName --image Ubuntu2204 --upgrade-policy-mode automatic --admin-username azureuser --generate-ssh-keys --vm-sku $vmssSku --instance-count $vmssCapacity --vnet-name $vnetName --subnet $subnetWeb --backend-pool-name $backendPoolName --lb $lbName --location $location

# Stap 10: NSG regels voor web subnet
az network nsg create --resource-group $resourceGroup --name NSGWeb --location $location
az network nsg rule create --resource-group $resourceGroup --nsg-name NSGWeb --name AllowHttp --protocol tcp --direction inbound --priority 1000 --destination-port-range 80 --access Allow
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetWeb --network-security-group NSGWeb

# Stap 11: IP van Load Balancer ophalen
lbIP=$(az network public-ip show --resource-group $resourceGroup --name $publicIPName --query "ipAddress" --output tsv)

echo " De Load Balancer is ingesteld met IP adres: $lbIP"
echo " De Jumpbox VM is aangemaakt"
echo " De VMSS is aangemaakt met $vmssCapacity instanties"
