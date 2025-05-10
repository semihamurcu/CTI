#!/bin/bash

resourceGroup="S1203586"
location="West Europe"
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
jumpboxIP="jumpboxIP"
vmssName="webVMSS"
nsgName="NSGWeb"

# Stap 2: Resources verwijderen

echo "Verwijderen van VM Scale Set..."
az vmss delete --resource-group $resourceGroup --name $vmssName --yes

echo "Verwijderen van Jumpbox VM..."
az vm delete --resource-group $resourceGroup --name $jumpboxName --yes

echo "Verwijderen van Load Balancer en onderdelen..."
az network lb rule delete --resource-group $resourceGroup --lb-name $lbName --name $lbRule
az network lb probe delete --resource-group $resourceGroup --lb-name $lbName --name $probeName
az network lb address-pool delete --resource-group $resourceGroup --lb-name $lbName --name $backendPoolName
az network lb delete --resource-group $resourceGroup --name $lbName

echo "Verwijderen van public IP..."
az network public-ip delete --resource-group $resourceGroup --name $publicIPName

echo "Verwijderen van NSG en loskoppelen van subnet..."
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetWeb --remove networkSecurityGroup
az network nsg delete --resource-group $resourceGroup --name $nsgName

echo "Verwijderen van subnets..."
az network vnet subnet delete --resource-group $resourceGroup --vnet-name $vnetName --name $subnetWeb
az network vnet subnet delete --resource-group $resourceGroup --vnet-name $vnetName --name $subnetDB

echo "Verwijderen van VNet..."
az network vnet delete --resource-group $resourceGroup --name $vnetName

echo "Alle componenten zijn verwijderd."
