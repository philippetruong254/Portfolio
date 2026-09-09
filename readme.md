# Enterprise Infrastructure & Hybrid Cloud Portfolio

**Author:** Philippe Truong  
**Copyright:** © 2026 Philippe Truong. All rights reserved.  
**Focus Areas:** Enterprise Routing & Switching (Cisco/Fortinet), Enterprise Network Telemetry (Zabbix/SNMPv3), Windows Server Infrastructure (AD DS/DNS/GPO), Microsoft Azure Cloud Networking, Azure Firewall, and Entra ID Hybrid Identity.

---

## Executive Summary

This repository contains reproducible, production-grade lab architectures, device configurations, network diagrams, and verification logs demonstrating end-to-end enterprise IT infrastructure capabilities.

All labs are designed to solve real-world enterprise operational challenges: high availability, secure identity boundaries, resilient WAN connectivity, enterprise observability, and seamless hybrid cloud integration.

---

## Portfolio Architecture & Lab Directory

| Lab | Domain | Key Technologies | Status |
| :--- | :--- | :--- | :---: |
| **[01. On-Premises Core Infrastructure](./01.\)WinServOnprem/)** | Systems & Core Routing | Dual Windows Server 2022 DCs, Active Directory Domain Services (AD DS), AD-Integrated DNS Replication, Cisco L3 Inter-VLAN Routing, DHCP Option 6 | 🟢 Completed |
| **[02. SD-WAN & Edge Redundancy](./02.\)SDWan/)** | Enterprise WAN / Security | Dual-WAN Failover (Primary Fiber + Cellular Backup), Performance SLA Probes, 802.3ad LACP, Fortinet FortiGate 40F | 🟢 Completed |
| **[03. Microsoft Entra ID Hybrid Identity & Hybrid Join](./03.\)EntraID/)** | Cloud Identity & Security | Microsoft Entra Connect, Password Hash Sync (PHS), Active Directory SCP, UPN Suffix Routing, Microsoft Entra Hybrid Join, Seamless SSO & PRT | 🟢 Completed |
| **[04. Azure Hub-and-Spoke Architecture & Azure Firewall](./4.\)AzureHub%26Spoke/)** | Cloud Networking & Security | Azure Hub-and-Spoke, VNet Peering Mesh, Azure Firewall Basic (L4/L7), UDR Forced Routing (0.0.0.0/0), NSG Microsegmentation, ARM IaC, Cloud FinOps | 🟢 Completed |
| **[05. Hybrid Cloud IPsec S2S VPN](./5.\)HybridS2SVPN/)** | Hybrid Cloud Connectivity | Route-Based Site-to-Site IPsec VPN (IKEv2), Dynamic Routing over IPsec (BGP ASN 65001 <-> 65515), Hybrid Conditional DNS Forwarding | 🟡 In Progress |
| **[06. Enterprise Network Telemetry & Alerting](./06.\)ZabbixTelemetry/)** | Telemetry & Observability | Zabbix 7.0 LTS, Cryptographic SNMPv3 (authPriv: SHA-256 / AES-128), 64-bit HC Interface Discards, SolarWinds Transferable Architecture | 🟢 Completed |

---

## Author & Copyright

Authored and copyrighted © 2026 Philippe Truong. All rights reserved.  
All architecture topologies, design documentation, and original configuration templates are the property of Philippe Truong.
