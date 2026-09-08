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
