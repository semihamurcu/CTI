#!/bin/bash

# Stap 1: Variabelen instellen
resourceGroup="S1203586"
location="westeurope"
vnetName="myVnet"
subnetWeb="subnetWeb"
subnetDB="subnetDB"
subnetManagement="subnetManagement"
lbName="webLoadBalancer"
publicIPName="webPublicIP"
frontendIPConfig="webFrontendIP"
backendPoolName="webBackendPool"
probeName="webProbe"
lbRule="webLBRule"
jumpboxName="jumpboxVM"
vmssName="webVMSS"
vmssSku="Standard_DS2_v2"
vmssCapacity="2"

# Stap 2: Maak Virtual Network en Subnets
# SubnetWeb
az network vnet create --resource-group $resourceGroup --name $vnetName \
  --address-prefix 10.0.0.0/16 --subnet-name $subnetWeb --subnet-prefix 10.0.1.0/24
# SubnetDatabase
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName \
  --name $subnetDB --address-prefix 10.0.2.0/24
# SubnetManagement
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName \
  --name $subnetManagement --address-prefix 10.0.3.0/24

# Stap 3: Public Load Balancer voor weblaag
az network public-ip create --resource-group $resourceGroup --name $publicIPName \
  --allocation-method Static --sku Standard --location $location

az network lb create --resource-group $resourceGroup --name $lbName --sku Standard \
  --frontend-ip-name $frontendIPConfig --public-ip-address $publicIPName

# Stap 4: Backend Pool en Health Probe voor Web LB
az network lb address-pool create --resource-group $resourceGroup --lb-name $lbName --name $backendPoolName

az network lb probe create --resource-group $resourceGroup --lb-name $lbName --name $probeName \
  --protocol Tcp --port 80 --interval 5 --threshold 2

az network lb rule create --resource-group $resourceGroup --lb-name $lbName --name $lbRule \
  --protocol Tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name $frontendIPConfig --backend-address-pool $backendPoolName --probe-name $probeName

# Stap 5: Jumpbox VM in Management Subnet
az vm create --resource-group $resourceGroup --name $jumpboxName --image Ubuntu2204 \
  --vnet-name $vnetName --subnet $subnetManagement --admin-username azureuser \
  --authentication-type ssh --ssh-key-value ~/.ssh/id_rsa.pub --zone 1

# Stap 6: VM Scale Set voor Weblaag (2 instanties automatisch door --instance-count)
az vmss create --resource-group $resourceGroup --name $vmssName --image Ubuntu2204 \
  --upgrade-policy-mode automatic --admin-username azureuser --ssh-key-value ~/.ssh/id_rsa.pub \
  --zones 1 2 --backend-pool-name $backendPoolName --vnet-name $vnetName --subnet $subnetWeb \
  --load-balancer $lbName --instance-count $vmssCapacity

# Stap 7: NSG's aanmaken en koppelen
az network nsg create --resource-group $resourceGroup --name nsgWeb --location $location
az network nsg rule create --resource-group $resourceGroup --nsg-name nsgWeb --name AllowHTTP \
  --protocol Tcp --direction Inbound --priority 100 --source-address-prefixes Internet --destination-port-ranges 80 --access Allow
az network nsg rule create --resource-group $resourceGroup --nsg-name nsgWeb --name AllowSSH \
  --protocol Tcp --direction Inbound --priority 110 --source-address-prefixes Internet --destination-port-ranges 22 --access Allow

az network nsg create --resource-group $resourceGroup --name nsgDB --location $location
az network nsg rule create --resource-group $resourceGroup --nsg-name nsgDB --name AllowMySQL \
  --protocol Tcp --direction Inbound --priority 100 --source-address-prefixes 10.0.1.0/24 --destination-port-ranges 3306 --access Allow

az network nsg create --resource-group $resourceGroup --name nsgMgmt --location $location
az network nsg rule create --resource-group $resourceGroup --nsg-name nsgMgmt --name AllowSSH \
  --protocol Tcp --direction Inbound --priority 100 --source-address-prefixes Internet --destination-port-ranges 22 --access Allow

az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetWeb --network-security-group nsgWeb
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetDB --network-security-group nsgDB
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetManagement --network-security-group nsgMgmt

# Stap 8: Interne Load Balancer voor Database
internalLBName="dbInternalLB"
dbFrontendIP="dbFrontend"
dbBackendPool="dbBackendPool"
dbProbe="dbProbe"
dbLBRule="dbLBRule"

az network lb create --resource-group $resourceGroup --name $internalLBName --sku Standard \
  --frontend-ip-name $dbFrontendIP --backend-pool-name $dbBackendPool \
  --vnet-name $vnetName --subnet $subnetDB --private-ip-address-version IPv4 --frontend-ip-configurations private \
  --location $location --zones 1 2

az network lb probe create --resource-group $resourceGroup --lb-name $internalLBName --name $dbProbe \
  --protocol Tcp --port 3306 --interval 5 --threshold 2

az network lb rule create --resource-group $resourceGroup --lb-name $internalLBName --name $dbLBRule \
  --protocol Tcp --frontend-port 3306 --backend-port 3306 \
  --frontend-ip-name $dbFrontendIP --backend-address-pool $dbBackendPool --probe-name $dbProbe

# Stap 9: Database backend VM's aanmaken en toevoegen aan ILB backend pool
az vm create --resource-group $resourceGroup --name dbVM1 --image Ubuntu2204 --vnet-name $vnetName \
  --subnet $subnetDB --admin-username azureuser --authentication-type ssh --ssh-key-value ~/.ssh/id_rsa.pub --zone 1

az vm create --resource-group $resourceGroup --name dbVM2 --image Ubuntu2204 --vnet-name $vnetName \
  --subnet $subnetDB --admin-username azureuser --authentication-type ssh --ssh-key-value ~/.ssh/id_rsa.pub --zone 2

az network nic ip-config address-pool add --address-pool $dbBackendPool --ip-config-name ipconfig1 \
  --nic-name dbVM1VMNic --resource-group $resourceGroup --lb-name $internalLBName

az network nic ip-config address-pool add --address-pool $dbBackendPool --ip-config-name ipconfig1 \
  --nic-name dbVM2VMNic --resource-group $resourceGroup --lb-name $internalLBName

# Stap 10: Output van belangrijke info
lbIP=$(az network public-ip show --resource-group $resourceGroup --name $publicIPName --query "ipAddress" --output tsv)
echo "De Web Load Balancer is ingesteld op IP-adres: $lbIP"
echo "De Jumpbox VM is beschikbaar in subnetManagement (Zone 1)"
echo "De Weblaag VMSS is gedeployed over Zone 1 en 2 (2 instanties automatisch aangemaakt)"
echo "De interne DB Load Balancer is beschikbaar in subnetDB (Zone 1 & 2)"
echo "Database VM's (dbVM1 en dbVM2) zijn aangemaakt en toegevoegd aan de backend pool van de ILB"
