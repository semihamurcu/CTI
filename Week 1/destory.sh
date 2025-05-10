#!/bin/bash

# Variabelen
resourceGroup="S1203586"
location="westeurope"
vnetName="myVnet"
subnetWeb="subnetWeb"
subnetDB="subnetDB"
subnetManagement="subnetManagement"
lbName="webLoadBalancer"
publicIPName="webPublicIP"
jumpboxName="jumpboxVM"
vmssName="webVMSS"
internalLBName="dbInternalLB"

echo "Verwijderen van VM's + bijhorende resources..."
az vm delete --resource-group $resourceGroup --name dbVM1 --yes --no-wait
az vm delete --resource-group $resourceGroup --name dbVM2 --yes --no-wait
az vm delete --resource-group $resourceGroup --name $jumpboxName --yes --no-wait

echo "Verwijderen van VM Scale Set..."
az vmss delete --resource-group $resourceGroup --name $vmssName

echo "Verwijderen van NICs..."
az network nic delete --resource-group $resourceGroup --name dbVM1VMNic
az network nic delete --resource-group $resourceGroup --name dbVM2VMNic

echo "Verwijderen van load balancers en IP..."
az network lb delete --resource-group $resourceGroup --name $lbName
az network lb delete --resource-group $resourceGroup --name $internalLBName
az network public-ip delete --resource-group $resourceGroup --name $publicIPName

echo "Ontkoppelen van NSG's van subnets..."
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetWeb --network-security-group ""
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetDB --network-security-group ""
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetManagement --network-security-group ""

echo "Verwijderen van NSG's..."
az network nsg delete --resource-group $resourceGroup --name nsgWeb
az network nsg delete --resource-group $resourceGroup --name nsgDB
az network nsg delete --resource-group $resourceGroup --name nsgMgmt

echo "Verwijderen van subnets en VNet..."
# Subnets worden automatisch verwijderd met VNet
az network vnet delete --resource-group $resourceGroup --name $vnetName

echo "Alles uit deploy.sh is succesvol verwijderd. ✅"
