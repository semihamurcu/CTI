# Overzicht van de infrastructuur
In dit project is een schaalbare cloudinfrastructuur gerealiseerd in Microsoft Azure, bestaande uit:
* Een Virtual Network (VNet) met twee subnets: subnetWeb en subnetDB
* Een Load Balancer met backend pool en health probe
* Een Virtual Machine Scale Set (VMSS) met twee instanties (Ubuntu 22.04)
* Een Jumpbox VM voor beheer
* Network Security Groups (NSG) voor toegangscontrole

![alt text](image.png)

##  Onderbouwing ontwerpkeuzes

### ⚙️ Aanpasbaarheid
- Dankzij subnet-segmentatie kunnen componenten los van elkaar beheerd of uitgebreid worden.
- Services zoals NSG’s en load balancers zijn modulair toe te voegen of aan te passen zonder het hele netwerk te herzien.

### 🛠 Beheerbaarheid
- Gebruik van **Jumpbox** maakt beheer van backend-VM’s mogelijk zonder directe externe toegang.
- **Network Security Groups (NSG’s)** per subnet zorgen voor eenvoudige toegangscontrole en overzicht.

### 📈 Schaalbaarheid
- Weblaag ondersteunt **VM Scale Sets**, wat automatische horizontale schaalvergroting mogelijk maakt.
- Load balancer backend pools kunnen eenvoudig uitgebreid worden met extra VM’s.

### 🛡 Security
- NSG's zorgen voor **microsegmentatie** en beperken verkeer per subnet.
- Jumpbox voorkomt directe toegang tot backend.
- Subnets scheiden web- en datalaag fysiek op netwerklaag.

### 🔁 Beschikbaarheid
- **Availability Zones** zorgen voor failover-mogelijkheden in meerdere datacenters.
- **Standard Load Balancers** ondersteunen redundantie en health probes.
