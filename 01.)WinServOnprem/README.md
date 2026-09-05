# Lab 01: On-Premises Core Infrastructure

**Author:** Philippe Truong  
**Copyright:** © 2026 Philippe Truong. All rights reserved.  
**Domain:** Windows Server Infrastructure (AD DS/DNS/GPO) & L3 routing and switching.

**Status:** 🟡 In Progress  

---

## 1. Executive Summary & Objective

This lab designs and deploys a resilient on-premises enterprise core network infrastructure. It simulates a corporate headquarters hosting dual Microsoft Windows Server 2022 Domain Controllers (`CORP-DC01` and `CORP-DC02`), an Active Directory-Integrated DNS infrastructure with multi-master replication, and a Cisco Layer 3 switching core handling Inter-VLAN routing and stateful DHCP leasing.

### Core Architectural Goals:
1. **Network Segmentation:** Implement Layer 3 stateless separation between the Server tier (VLAN 10) and Client tier (VLAN 20) via SVI on switch. network between router and switch is on 10.10.9.0.
2. **Decoupled L3 and DHCP Architecture:** Offload DHCP leasing and vlans to the Cisco Core Switch SVI to ensure workstations acquire IP configuration independent of Windows Server boot cycles and rapid communication between vlans via SVI
3. **High-Availability Identity & DNS:** Deploy dual Windows Server 2022 Domain Controllers (`corp.local`) with active-active AD-integrated DNS replication and SRV locator records.
4. **Resilient Edge NAT Gateway:** Route all internal subnets through a dedicated Cisco Edge router performing PAT (NAT Overload) to simulate secure internet egress without exposing internal topologies.

---

## 2. Network Topology Diagram

![EVE-NG On-Premises Core Infrastructure Topology](image.png)

---

## 3. IP Addressing & VLAN Allocation

| Device / Interface | Role | Subnet | IP Address | Gateway | Credentials / DNS |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`EDGE-RTR01` Gi0/0** | Outside WAN (Cloud0) | `192.168.3.0/24` | `192.168.3.13` (DHCP) | `192.168.3.1` | Assigned by ISP/LAN |
| **`EDGE-RTR01` Gi0/1** | Inside Transit Gateway | `10.10.9.0/24` | `10.10.9.1/24` | N/A | Local Transit Gateway |
| **`CORE-SW01` Gi0/0** | Routed Uplink | `10.10.9.0/24` | `10.10.9.2/24` | `10.10.9.1` | Local Routed Uplink |
| **`CORE-SW01` Vlan10** | Server SVI Default Gateway | `10.10.10.0/24` | `10.10.10.1/24` | Local SVI | Local SVI |
| **`CORE-SW01` Vlan20** | Client SVI Default Gateway | `10.10.20.0/24` | `10.10.20.1/24` | Local SVI | Local SVI |
| **`CORP-DC01` (DCS01)** | Primary Domain Controller | `10.10.10.0/24` | `10.10.10.10/24` | `10.10.10.1` | Admin: `Cisco1` <br/> DSRM: `Cisco1Restore` |
| **`CORP-DC02` (DCS02)** | Replica Domain Controller | `10.10.10.0/24` | `10.10.10.11/24` | `10.10.10.1` | Admin: `Cisco1` <br/> DSRM: `Cisco1Restore` |
| **`CLIENT-PC01`** | Domain Workstation | `10.10.20.0/24` | Dynamic (DHCP) | `10.10.20.1` | DNS: `10.10.10.10`, `10.10.10.11` |

---

## 4. Cisco Network Configuration Artifacts

### 4.1. Edge Router (`EDGE-RTR01`)
```cisco
hostname EDGE-RTR01
!
ip domain-name corp.local
!
interface GigabitEthernet0/0
 description WAN-to-Internet-Cloud0
 ip address dhcp
 ip nat outside
 no shutdown
!
interface GigabitEthernet0/1
 description Transit-Gateway-to-CORE-SW01
 ip address 10.10.9.1 255.255.255.0
 ip nat inside
 no shutdown
!
ip access-list standard NAT-PERMIT
 permit 10.10.0.0 0.0.255.255
!
ip nat inside source list NAT-PERMIT interface GigabitEthernet0/0 overload
!
ip route 10.10.10.0 255.255.255.0 10.10.9.2
ip route 10.10.20.0 255.255.255.0 10.10.9.2
```

![Cisco Edge Router Running Configuration](assets/01-cisco-edge-rtr01-running-config.png)

### 4.2. Layer 3 Core Switch (`CORE-SW01`)
```cisco
hostname CORE-SW01
!
ip routing
ip domain-name corp.local
!
interface GigabitEthernet0/0
 no switchport
 description Uplink-to-EDGE-RTR01
 ip address 10.10.9.2 255.255.255.0
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 10.10.9.1
!
vlan 10
 name Servers-DCs
vlan 20
 name Clients-Workstations
!
interface Vlan10
 description Server-Gateway
 ip address 10.10.10.1 255.255.255.0
 no shutdown
!
interface Vlan20
 description Client-Gateway
 ip address 10.10.20.1 255.255.255.0
 no shutdown
!
interface GigabitEthernet0/1
 description Access-to-CORP-DC01
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast edge
 no shutdown
!
interface GigabitEthernet0/2
 description Access-to-CORP-DC02
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast edge
 no shutdown
!
interface GigabitEthernet1/1
 description Access-to-Clients-VLAN20
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast edge
 no shutdown
!
ip dhcp excluded-address 10.10.20.1 10.10.20.50
!
ip dhcp pool CLIENT-POOL
 network 10.10.20.0 255.255.255.0
 default-router 10.10.20.1
 dns-server 10.10.10.10 10.10.10.11
 domain-name corp.local
 lease 1
```

![Cisco Core Switch Running Configuration](assets/02-cisco-core-sw01-running-config.png)

---

## 5. Active Directory & Windows Server Deployment

### 5.1. Static IP & Network Interface Configuration
Before promoting the server, static IP addressing and local loopback DNS resolution are assigned to ensure seamless AD DS service binding.

![CORP-DC01 Static IP and DNS Configuration](assets/04-dc01-static-ip-and-dns-config.png)

### 5.2. `CORP-DC01` Primary Domain Controller Promotion

#### Active Directory Domain Services Forest Configuration
* **Forest Root Domain:** `corp.local`
* **NetBIOS Domain Name:** `CORP`
* **Forest & Domain Functional Level:** Windows Server 2016
* **Capabilities:** Domain Name System (DNS) Server, Global Catalog (GC)

![Active Directory Configuration Wizard - Domain Controller Options](assets/05-adds-wizard-forest-dc-options.png)

#### Prerequisites Validation Check
All prerequisite validation checks passed, verifying connectivity, administrative permissions, and cryptographic capabilities.

![Active Directory Configuration Wizard - Prerequisites Check Passed](assets/06-adds-wizard-prerequisites-passed.png)

#### PowerShell Promotion Deployment Automation
```powershell
# Windows PowerShell Script for AD DS Forest Deployment
Import-Module ADDSDeployment
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "corp.local" `
    -DomainNetbiosName "CORP" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
```

### 5.3. `CORP-DC02` Replica Domain Controller Promotion

#### Prerequisites Validation Check
Prerequisite validation check successfully passed, verifying RPC, LDAP, and Kerberos connectivity to `CORPDC01.corp.local`.

![CORP-DC02 AD DS Prerequisites Check Passed](assets/07-dc02-adds-prerequisites-passed.png)

#### PowerShell Promotion Deployment Script
```powershell
# Windows PowerShell Script for AD DS Replica Domain Controller Deployment
Import-Module ADDSDeployment
Install-ADDSDomainController `
    -NoGlobalCatalog:$false `
    -CreateDnsDelegation:$false `
    -Credential (Get-Credential) `
    -CriticalReplicationOnly:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainName "corp.local" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SiteName "Default-First-Site-Name" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
```

![CORP-DC02 PowerShell Promotion Deployment Automation](assets/08-dc02-powershell-deployment-script.png)


---

## 6. Verification & Proof of Competence

### 6.1. Network Connectivity & Routing Verification
Direct ICMP verification from the Cisco Layer 3 switch confirming inter-subnet gateway reachability to `EDGE-RTR01` (`10.10.9.1`) and external WAN egress to the public internet (`8.8.8.8`).

```text
CORE-SW01# ping 10.10.9.1
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.10.9.1, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 2/3/4 ms

CORE-SW01# ping 8.8.8.8
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 8.8.8.8, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 8/9/12 ms
```

![Cisco Core Switch Ping Verification to Transit Gateway and Internet](assets/03-cisco-core-sw01-ping-verification.png)

### 6.2. Active Directory Multi-Master Replication Health
*(Diagnostic logs will be populated upon DC01 and DC02 online verification).*

---

## 7. Author & Copyright Notice

Authored and copyrighted © 2026 Philippe Truong. All rights reserved.  
All topology designs, configuration templates, and implementation documentation are the intellectual property of Philippe Truong.