# Azure Networking: The 5 Core Conceptual Pillars

A high-level conceptual guide to the primary networking services in Microsoft Azure.

```
                     [ Global / Internet Users ]
                                  |
            +---------------------+---------------------+
            |                                           |
            v                                           v
 [ Azure CDN (Edge Caching) ]              [ Azure Application Gateway ]
 (Static files, images, videos)            (Layer 7: HTTP/HTTPS, URLs, WAF)
                                                        |
                                                        v
                                          [ Azure Load Balancer (L4) ]
                                          (Layer 4: TCP/UDP, Port rules)
                                                        |
                                                        v
+-------------------------------------------------------+---------------------+
|  Azure Virtual Network (VNet)                                               |
|  (Private isolated network boundary in the cloud)                           |
|                                                                             |
|   +-----------------------+                    +------------------------+   |
|   | Web / App Subnet      |                    | Backend / DB Subnet    |   |
|   | VMs / Containers      |                    | Database VMs           |   |
|   +-----------+-----------+                    +------------------------+   |
|               |                                                             |
|               +-----------------------+                                     |
|                                       |                                     |
+---------------------------------------+-------------------------------------+
                                        |
                         [ Azure VPN Gateway (Hybrid) ]
                         (Encrypted IPsec tunnel)
                                        |
                                        v
                            [ On-Premises Network ]
                            (Offices, Datacenters)
```

---

## 1. Azure Virtual Network (VNet)
* **What it is**: Your private, isolated slice of the Microsoft Azure cloud.
* **Analogy**: A private corporate datacenter rack or private VRF.
* **Key Concepts**:
  * **Address Space**: You assign private RFC 1918 IP addresses (e.g., `10.0.0.0/16`).
  * **Subnets**: You divide the VNet into smaller segments (e.g., Web tier, Database tier).
  * **Isolation**: By default, no traffic enters from the internet unless you explicitly allow it.
  * **VNet Peering**: Directly connects two separate VNets over Microsoft's high-speed global backbone.

---

## 2. Azure VPN Gateway
* **What it is**: A managed gateway that connects your on-premises network to Azure over the public internet using encrypted tunnels.
* **Analogy**: The corporate site-to-site IPsec VPN tunnel between branch offices.
* **Key Concepts**:
  * **Site-to-Site (S2S)**: Connects an entire on-premises office/datacenter router to Azure.
  * **Point-to-Site (P2S)**: Individual remote workers running a VPN client software on their laptops connecting into Azure.
  * **VNet-to-VNet**: Securely connects two VNets in different regions.
  * **Encrypted transit**: All traffic travels over the public internet wrapped in IPsec/IKE encryption.

---

## 3. Azure Load Balancer (Layer 4)
* **What it is**: An ultra-high-throughput, ultra-low-latency load balancer operating at **Layer 4 (Transport Layer)**.
* **Analogy**: A traffic cop directing cars based strictly on **IP address and Port number**.
* **Key Concepts**:
  * **Protocols**: Works with **TCP** and **UDP** only. It does not inspect HTTP headers, cookies, or URLs.
  * **Types**:
    * **Public Load Balancer**: Distributes incoming internet traffic to backend VMs.
    * **Internal (Private) Load Balancer**: Distributes internal traffic between tiers (e.g., Web tier to Database tier).
  * **Health Probes**: Monitors backend servers; if a server stops responding, it redirects traffic to healthy servers.

---

## 4. Azure Application Gateway (Layer 7)
* **What it is**: An intelligent web traffic load balancer and reverse proxy operating at **Layer 7 (Application Layer)**.
* **Analogy**: A concierge in a building lobby who reads your request and directs you to the exact department.
* **Key Concepts**:
  * **URL-based Routing**: Routes requests based on the URL path:
    * `contoso.com/images/*` $\rightarrow$ routes to Image Server Pool.
    * `contoso.com/video/*` $\rightarrow$ routes to Video Server Pool.
  * **SSL/TLS Termination**: Decrypts HTTPS traffic at the gateway so your backend servers don't waste CPU decrypting packets.
  * **Cookie-based Session Affinity**: Keeps a user's session pinned to the same backend server.
  * **Web Application Firewall (WAF)**: Built-in security that protects against web attacks (SQL injection, Cross-Site Scripting / XSS, OWASP top 10).

---

## 5. Azure Content Delivery Network (CDN)
* **What it is**: A globally distributed network of edge caching servers designed to deliver heavy web content to users with minimum latency.
* **Analogy**: Warehouses placed in every major city so deliveries take 1 hour instead of 5 days from the main factory.
* **Key Concepts**:
  * **Edge Caching**: Stores static files (images, CSS, JavaScript, PDF downloads, videos) at "Points of Presence" (PoPs) closest to the user.
  * **Reduced Server Load**: Users download heavy assets from Azure's edge servers rather than hitting your origin web servers.
  * **Global Performance**: A user in Tokyo loads your Houston-hosted website almost instantly because images are served from a local Tokyo edge cache.

---

## Quick Comparison: Load Balancer vs. Application Gateway

| Feature | Azure Load Balancer | Azure Application Gateway |
| :--- | :--- | :--- |
| **OSI Layer** | **Layer 4** (Transport) | **Layer 7** (Application) |
| **Routing Decisions** | IP address, Port, Protocol (TCP/UDP) | URL path, HTTP headers, Cookies, Hostnames |
| **SSL/TLS Termination** | No (passes through) | Yes (decrypts at the gateway) |
| **Web App Firewall (WAF)**| No | Yes (protects against OWASP attacks) |
| **Best For** | Ultra-fast TCP/UDP traffic, gaming, internal tier balancing | Web apps, APIs, microservices, HTTPS websites |

---

---

## 6. Enterprise Hub-and-Spoke Deployment Architecture

The **Hub-and-Spoke** topology is the gold standard for enterprise cloud architecture. It centralizes shared infrastructure (VPN gateways, next-generation firewalls, identity services, and DNS) in a central **Hub VNet**, while isolating application workloads into separate **Spoke VNets**.

```
                           +-------------------------------------+
                           |     On-Premises Industrial Plant    |
                           |   FortiGate 40F (10.10.0.0/16)      |
                           +------------------+------------------+
                                              |
                                              | Route-Based S2S IPsec VPN
                                              | (BGP ASN 65001 <-> 65515)
                                              v
+---------------------------------------------------------------------------------------------------+
|  HUB VNET: vnet-hub-southcentralus (10.100.0.0/16)                                                |
|                                                                                                   |
|    [ GatewaySubnet (10.100.0.0/24) ]             [ AzureFirewallSubnet (10.100.1.0/24) ]          |
|    - Virtual Network Gateway (VPN/ExpressRoute)   - Azure Firewall / FortiGate-VM (10.100.1.4)     |
|                                                                                                   |
|    [ ManagementSubnet (10.100.2.0/24) ]                                                           |
|    - Cloud Domain Controller / Jumpbox (NSG-Management)                                           |
+--------------------+---------------------------------------------------------+--------------------+
                     |                                                         |
        VNet Peering | (AllowGatewayTransit)                      VNet Peering | (AllowGatewayTransit)
        (Encrypted)  | (UseRemoteGateways)                        (Encrypted)  | (UseRemoteGateways)
                     v                                                         v
+------------------------------------+                    +------------------------------------+
|  SPOKE 1: vnet-spoke-prod          |                    |  SPOKE 2: vnet-spoke-shared-services|
|  (10.200.0.0/16)                   |                    |  (10.201.0.0/16)                   |
|                                    |                    |                                    |
|  [ AppSubnet: 10.200.1.0/24 ]      |                    |  [ SharedSubnet: 10.201.1.0/24 ]   |
|  - Production Workloads / APIs     |                    |  - Logging / Telemetry / Proxies   |
|  - Protected by NSG-Prod-App       |                    |  - Protected by NSG-Shared         |
|  - UDR: 0.0.0.0/0 -> 10.100.1.4    |                    |  - UDR: 0.0.0.0/0 -> 10.100.1.4    |
+------------------------------------+                    +------------------------------------+
```

---

### Network Security Group (NSG) Stateful Rule Table

Network Security Groups operate as stateful Layer 4 firewalls protecting subnets and NICs. Rules are evaluated in priority order (lowest number takes precedence):

#### Subnet NSG: `nsg-spoke-prod-app` (Attached to `AppSubnet`)
| Priority | Direction | Name | Source | Source Port | Destination | Dest Port | Protocol | Action | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **100** | Inbound | `Allow-OnPrem-SSH-RDP` | `10.10.0.0/16` | Any | `VirtualNetwork` | `22, 3389` | TCP | **Allow** | Management access only from on-prem corporate subnets |
| **110** | Inbound | `Allow-Hub-Management` | `10.100.2.0/24` | Any | `VirtualNetwork` | `Any` | Any | **Allow** | Inter-tier management from central jumpbox |
| **200** | Inbound | `Allow-Internal-HTTP-HTTPS` | `10.100.0.0/16` | Any | `VirtualNetwork` | `80, 443` | TCP | **Allow** | Reverse proxy traffic from Hub firewall/WAF |
| **4096** | Inbound | `Deny-All-Inbound-Internet` | `Internet` | Any | `VirtualNetwork` | Any | Any | **Deny** | Explicit drop for any unsolicited internet ingress |
| **100** | Outbound| `Allow-Sync-To-OnPrem` | `VirtualNetwork`| Any | `10.10.0.0/16` | `389, 88, 53` | Any | **Allow** | Active Directory and DNS sync back to on-prem |
| **200** | Outbound| `Allow-Outbound-HTTPS-Azure` | `VirtualNetwork`| Any | `AzureCloud` | `443` | TCP | **Allow** | Azure APIs, telemetry, and platform services |
| **4096** | Outbound| `Deny-Direct-Internet-Egress`| `VirtualNetwork`| Any | `Internet` | Any | Any | **Deny** | Force all egress through Hub Firewall via UDR |

---

### Automated Deployment via Azure CLI

This bash/Azure CLI script deploys the resource group, Hub VNet, Spoke VNet, subnets, NSGs, and establishes bidirectional peering:

```bash
#!/bin/bash
# Enterprise Hub-and-Spoke Deployment Script
set -e

RESOURCE_GROUP="rg-enterprise-network-prod"
LOCATION="southcentralus"

echo "[1/6] Creating Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "[2/6] Deploying Hub Virtual Network & Subnets..."
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name vnet-hub-southcentralus \
    --address-prefixes 10.100.0.0/16 \
    --subnet-name GatewaySubnet \
    --subnet-prefixes 10.100.0.0/24

az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name vnet-hub-southcentralus \
    --name AzureFirewallSubnet \
    --address-prefixes 10.100.1.0/24

az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name vnet-hub-southcentralus \
    --name ManagementSubnet \
    --address-prefixes 10.100.2.0/24

echo "[3/6] Deploying Spoke Virtual Network & Workload Subnet..."
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name vnet-spoke-prod \
    --address-prefixes 10.200.0.0/16 \
    --subnet-name AppSubnet \
    --subnet-prefixes 10.200.1.0/24

echo "[4/6] Creating & Associating Network Security Groups (NSGs)..."
az network nsg create \
    --resource-group $RESOURCE_GROUP \
    --name nsg-spoke-prod-app

# Rule: Allow on-prem management only
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name nsg-spoke-prod-app \
    --name Allow-OnPrem-Mgmt \
    --priority 100 \
    --source-address-prefixes 10.10.0.0/16 \
    --destination-port-ranges 22 3389 \
    --protocol Tcp \
    --access Allow

# Rule: Deny all direct inbound internet
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name nsg-spoke-prod-app \
    --name Deny-Internet-Inbound \
    --priority 4096 \
    --source-address-prefixes Internet \
    --destination-port-ranges '*' \
    --protocol '*' \
    --access Deny

# Associate NSG to AppSubnet
az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name vnet-spoke-prod \
    --name AppSubnet \
    --network-security-group nsg-spoke-prod-app

echo "[5/6] Establishing Bidirectional VNet Peering..."
# Hub -> Spoke Peering (Allow Gateway Transit)
az network vnet peering create \
    --resource-group $RESOURCE_GROUP \
    --name peer-hub-to-spoke-prod \
    --vnet-name vnet-hub-southcentralus \
    --remote-vnet vnet-spoke-prod \
    --allow-vnet-access \
    --allow-forwarded-traffic \
    --allow-gateway-transit

# Spoke -> Hub Peering (Use Remote Gateways)
az network vnet peering create \
    --resource-group $RESOURCE_GROUP \
    --name peer-spoke-prod-to-hub \
    --vnet-name vnet-spoke-prod \
    --remote-vnet vnet-hub-southcentralus \
    --allow-vnet-access \
    --allow-forwarded-traffic \
    --use-remote-gateways

echo "[6/6] Hub-and-Spoke Network Architecture Successfully Deployed!"
```

---

## 7. Author & Copyright Notice

Authored and copyrighted © 2026 Philippe Truong. All rights reserved.  
All architecture topologies, design documentation, and implementation guides are the property of Philippe Truong.
