# Enterprise Infrastructure & Hybrid Cloud Portfolio

**Author:** Philippe Truong  
**Copyright:** © 2026 Philippe Truong. All rights reserved.  
**Focus Areas:** Enterprise Routing & Switching (Cisco/Fortinet), Windows Server Infrastructure (AD DS/DNS/GPO), Microsoft Azure Networking, and Entra ID.

---

## Executive Summary

This repository contains reproducible, production-grade lab architectures, device configurations, network diagrams, and verification logs demonstrating end-to-end enterprise IT infrastructure capabilities.

All labs are designed to solve real-world enterprise operational challenges: high availability, secure identity boundaries, resilient WAN connectivity, and seamless hybrid cloud integration.

---

## Portfolio Architecture & Lab Directory

| Lab | Domain | Key Technologies | Status |
| :--- | :--- | :--- | :---: |
| **[01. On-Premises Core Infrastructure](./01.\)WinServOnprem/)** | Systems & Core Routing | Dual Windows Server 2022 DCs, Active Directory Domain Services (AD DS), AD-Integrated DNS Replication, Cisco L3 Inter-VLAN Routing, DHCP Option 6 | 🟡 In Progress |
| **[02. SD-WAN & Edge Redundancy](./02.\)SDWan/)** | Enterprise WAN / Security | Dual-WAN Failover (Primary ISP + Secondary Backup), IP SLA Probes, Route Tracking, Fortinet / Cisco Edge | ⚪ Planned |
| **[03. Microsoft Entra ID](./03.\)EntraID/)** | Cloud Identity & Security | User & Security Group Governance, Role-Based Access Control (RBAC), Conditional Access (MFA & Compliance Enforcement) | ⚪ Planned |
| **[04. Azure Hub-and-Spoke Cloud Network](./4.\)AzureHub%26Spoke/)** | Cloud Infrastructure | Azure Virtual Networks (VNets), Hub-and-Spoke Architecture, VNet Peering, Network Security Groups (NSGs), User Defined Routes (UDRs) | ⚪ Planned |
| **[05. Hybrid Cloud IPsec S2S VPN](./5.\)HybridS2SVPN/)** | Hybrid Cloud Connectivity | Route-Based Site-to-Site IPsec VPN (IKEv2), Dynamic Routing over IPsec (BGP ASN 65001 <-> 65515), Hybrid Conditional DNS Forwarding | ⚪ Planned |

---

## Technical Skills Matrix

* **Routing & Switching:** Cisco IOS-XE, Inter-VLAN Routing (SVIs), OSPF, BGP, 802.1Q Trunking, EtherChannel, DHCP Relay / IP Helper.
* **Network Security & WAN:** Route-based IPsec VPNs, IKEv2, NAT/PAT, Access Control Lists (ACLs), Stateful Firewall Inspection, Dual-WAN Failover with IP SLA.
* **Directory Services & Systems:** Windows Server 2022, Active Directory Domain Services, AD-Integrated DNS, Group Policy Objects (GPOs), FSMO Roles, DHCP Scope & Options.
* **Cloud & Identity:** Microsoft Azure Virtual Networks, Hub-Spoke Peering, NSG Security Rules, Microsoft Entra ID (Azure AD), Conditional Access Policies, Privileged Identity Management (PIM).
* **Virtualization & Tooling:** EVE-NG Professional, Wireshark Packet Analysis, PowerShell Automation, Git & GitHub.

---

## Author & Copyright

Authored and copyrighted © 2026 Philippe Truong. All rights reserved.  
All architecture topologies, design documentation, and original configuration templates are the property of Philippe Truong.

