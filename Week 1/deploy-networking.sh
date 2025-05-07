# Stap 1: Variabelen instellen
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

# Stap 2: Resource group maken 

# Note: Vanwege school mag dit dus net

#az group create --name $resourceGroup --location $location



# Stap 3: VNET en subnets maken
az network vnet create --resource-group $resourceGroup --name $vnetName --address-prefix 10.0.0.0/16 --subnet-name $subnetWeb --subnet-prefix 10.0.1.0/24
az network vnet subnet create --resource-group $resourceGroup --vnet-name $vnetName --name $subnetDB --address-prefix 10.0.2.0/24

# Stap 4: Load Balancer aanmaken
az network lb create --resource-group $resourceGroup --name $lbName --sku Standard --frontend-ip-name $frontendIPConfig --public-ip-address $publicIPName --location $location

# Stap 5: Public IP maken
az network public-ip create --resource-group $resourceGroup --name $publicIPName --allocation-method Static --sku Standard --location $location

# Stap 6: Backend pool aanmaken
az network lb address-pool create --resource-group $resourceGroup --lb-name $lbName --name $backendPoolName

# Stap 7: Health probe configureren (voor web)
az network lb probe create --resource-group $resourceGroup --lb-name $lbName --name $probeName --protocol Tcp --port 80 --interval 5 --threshold 2

# Stap 8: Load balancer rule voor HTTP-verkeer instellen
az network lb rule create --resource-group $resourceGroup --lb-name $lbName --name $lbRule --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name $frontendIPConfig --backend-address-pool-name $backendPoolName --probe-name $probeName

# Stap 9: VM's toevoegen aan de backend pool (web servers)
az network lb address-pool address add --resource-group $resourceGroup --lb-name $lbName --address "10.0.1.4" --address "10.0.1.5" --address-pool-name $backendPoolName

# Stap 10: VM's maken (bijvoorbeeld web-VM's)
az vm create --resource-group $resourceGroup --name VM1 --image UbuntuLTS --vnet-name $vnetName --subnet $subnetWeb --admin-username azureuser --generate-ssh-keys
az vm create --resource-group $resourceGroup --name VM2 --image UbuntuLTS --vnet-name $vnetName --subnet $subnetWeb --admin-username azureuser --generate-ssh-keys

# Stap 11: NSG regels voor web en database subnets
az network nsg create --resource-group $resourceGroup --name NSGWeb
az network nsg rule create --resource-group $resourceGroup --nsg-name NSGWeb --name AllowHttp --protocol tcp --direction inbound --priority 1000 --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 80 --access allow
az network vnet subnet update --resource-group $resourceGroup --vnet-name $vnetName --name $subnetWeb --network-security-group NSGWeb

# Stap 12: Het IP van de Load Balancer ophalen
lbIP=$(az network public-ip show --resource-group $resourceGroup --name $publicIPName --query "ipAddress" --output tsv)

echo "De Load Balancer is ingesteld en heeft het IP adres: $lbIP"
