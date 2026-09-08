# Lab 06: Enterprise Network Telemetry & Alerting (Zabbix 7.0 LTS & SNMPv3 authPriv)

**Author:** Philippe Truong  
**Copyright:** © 2026 Philippe Truong. All rights reserved.  
**Platform:** Zabbix Server 7.0 LTS, Cisco IOS-XE (Catalyst), Fortinet FortiOS (FortiGate 40F)  
**Focus Areas:** Centralized Network Observability, Cryptographic SNMPv3 (`authPriv`), Low-Level Discovery (LLD), 64-bit High-Capacity Interface Metrics, Automated Threshold Alerting, and SolarWinds Orion Transferable Architecture.

---

## 1. Executive Summary & Architecture Topology

This lab implements an enterprise-grade network telemetry, performance monitoring, and automated incident alerting architecture utilizing **Zabbix 7.0 LTS** and cryptographic **SNMPv3 with `authPriv`** (SHA-256 authentication and AES-128 privacy encryption).

The deployment monitors physical and virtual network infrastructure across core campus switching (Cisco Catalyst) and edge next-generation firewalls (Fortinet FortiGate), tracking interface throughput, packet discards, link state transitions, CPU/memory thresholds, and routing protocol adjacencies.

```
+---------------------------------------------------------------------------------------------------+
|                                 ZABBIX 7.0 LTS OBSERVABILITY PLATFORM                             |
|                                       (IP: 10.10.10.250)                                          |
|                                                                                                   |
|    [ PostgreSQL 16 DB ] <===> [ Zabbix Server Daemon ] <===> [ Zabbix Nginx / PHP Web UI ]       |
|    - Time-series metrics       - Poller & Trapper engine      - Dashboards & Geo-Maps             |
|    - Historical trends         - Trigger evaluation engine    - Alert notification webhooks       |
+------------------------------------------+--------------------------------------------------------+
                                           ^
                                           | SNMPv3 Inbound Traps (UDP 162)
                                           | SNMPv3 Polling Queries (UDP 161)
                                           | [SHA-256 Auth + AES-128 Privacy Encryption]
                     +---------------------+---------------------+
                     |                                           |
+--------------------v--------------------+ +--------------------v--------------------+
|  CORE-SW01: Cisco Catalyst IOS-XE       | |  EDGE-FW01: Fortinet FortiGate 40F       |
|  IP: 10.10.10.1 (SVI / Management)      | |  IP: 10.10.10.2 (LAN / Management)       |
|                                         | |                                         |
|  - SNMPv3 User: zabbix-poller           | |  - SNMPv3 User: zabbix-poller           |
|  - 64-bit HC Interface Discard Triggers | |  - SD-WAN SLA & Tunnel Metrics          |
|  - Spanning-Tree Topology Change Traps  | |  - UTM Inspection & CPU/Memory Traps    |
+-----------------------------------------+ +-----------------------------------------+
```

---

## 2. Transferable Knowledge: SolarWinds Orion to Zabbix 7.0

In enterprise IT infrastructure, the foundational principles of telemetry, Simple Network Management Protocol (SNMP), Management Information Bases (MIBs), and Object Identifiers (OIDs) are universal open standards. Experience with legacy enterprise suites like **SolarWinds Network Performance Monitor (NPM)** directly translates to open-source enterprise platforms like **Zabbix**:

| SolarWinds Orion (NPM / NCM) | Zabbix 7.0 LTS Architecture | Engineering Function & Operational Reality |
| :--- | :--- | :--- |
| **NPM Polling Engine** | **Zabbix Server / Zabbix Proxy** | Multi-threaded daemons executing scheduled ICMP pings and SNMP queries against managed endpoints. |
| **Orion Database (MS SQL)** | **Zabbix Database (PostgreSQL/TimescaleDB)** | Stores configuration state, real-time metrics, and partitioned historical time-series telemetry. |
| **MIBs & Universal Device Pollers (UnDP)** | **Zabbix Templates & Item Prototypes** | Translates numeric ASN.1 OIDs (e.g., `1.3.6.1.2.1.31.1.1.1.6`) into human-readable metric values (e.g., `Inbound Bandwidth (bps)`). |
| **Network Sonar Discovery Wizard** | **Network Discovery & Low-Level Discovery (LLD)** | Automatically scans subnets (`10.10.10.0/24`), identifies device types, and dynamically provisions interface items and graphs without manual entry. |
| **Orion Alert Manager** | **Zabbix Triggers & Problem Actions** | Evaluates real-time metric thresholds (e.g., packet drop $> 2\%$) and fires automated notifications (Email, Slack, Webhook). |
| **High Availability (Orion HA)** | **Zabbix Native HA Cluster** | Active/Passive failover node clustering preventing monitoring blind spots during server maintenance. |

---

## 3. Cryptographic SNMPv3 Configuration (authPriv)

> [!IMPORTANT]
> **Legacy SNMPv1 and SNMPv2c are strictly forbidden in modern enterprise environments.** Plaintext community strings (e.g., `public`, `private`) expose network topology and interface statistics to packet sniffing. 
> 
> This lab implements **SNMPv3 with `authPriv`**:
> * **Authentication:** HMAC-SHA-256 (Guarantees packet integrity and verifies sender identity).
> * **Privacy (Encryption):** AES-128 CFB (Encrypts the entire SNMP PDU payload, preventing eavesdropping).

### A. Cisco IOS-XE Switch Configuration (`CORE-SW01`)
```cisco
configure terminal
hostname CORE-SW01

! 1. Define SNMPv3 View restricting access to standard MIB tree
snmp-server view V3-MONITOR-VIEW iso included

! 2. Create SNMPv3 Group enforcing authPriv security level
snmp-server group NOC-ADMIN-GROUP v3 priv read V3-MONITOR-VIEW

! 3. Create SNMPv3 User with SHA-256 Authentication and AES-128 Encryption
snmp-server user zabbix-poller NOC-ADMIN-GROUP v3 auth sha256 AuthSecretPass2026! priv aes 128 PrivSecretPass2026!

! 4. Configure Trap Destination for Automated Alerts
snmp-server host 10.10.10.250 version 3 priv zabbix-poller
snmp-server enable traps snmp authentication linkdown linkup coldstart warmstart
snmp-server enable traps config
snmp-server enable traps ospf state-change
snmp-server source-interface traps Vlan10

! 5. Location and Contact Metadata
snmp-server location "Houston Data Center - Rack 04"
snmp-server contact "Philippe Truong - NetAdmin"
exit
write memory
```

---

### B. Fortinet FortiOS Firewall Configuration (`EDGE-FW01`)
```fortios
# 1. Enable SNMP Agent globally
config system snmp sysinfo
    set status enable
    set description "FortiGate 40F Edge Firewall"
    set contact-info "Philippe Truong - NetAdmin"
    set location "Houston Plant - MDF Rack 01"
end

# 2. Configure SNMPv3 User with SHA-256 and AES-128
config system snmp user
    edit "zabbix-poller"
        set status enable
        set trap-status enable
        set trap-lport 162
        set trap-rport 162
        set security-level auth-priv
        set auth-proto sha256
        set auth-pwd AuthSecretPass2026!
        set priv-proto aes128
        set priv-pwd PrivSecretPass2026!
        set queries enable
        set query-port 161
        set ha-direct enable
    next
end

# 3. Allow SNMP traffic on internal management interface (lan3 / LACP-Bond)
config system interface
    edit "LACP-Bond"
        append allowaccess snmp ping
    next
end
```

---

## 4. Zabbix Template & Low-Level Discovery (LLD) Engineering

To eliminate manual configuration overhead, devices are attached to standardized SNMP templates utilizing **Low-Level Discovery (LLD)**:

### 1. Host Macro Definition
Credentials are parameterized using encrypted Zabbix Host Macros:
* `{$SNMP_SECNAME}` $ightarrow$ `zabbix-poller`
* `{$SNMP_AUTHPROTOCOL}` $ightarrow$ `SHA256`
* `{$SNMP_AUTHPASSPHRASE}` $ightarrow$ `AuthSecretPass2026!`
* `{$SNMP_PRIVPROTOCOL}` $ightarrow$ `AES128`
* `{$SNMP_PRIVPASSPHRASE}` $ightarrow$ `PrivSecretPass2026!`

### 2. High-Capacity 64-Bit Interface Counters (Counter64)
Standard 32-bit SNMP counters (`ifInOctets` / `ifOutOctets`) roll over every **34 seconds** on a fully saturated 1 Gbps link, corrupting bandwidth graphs. This deployment strictly enforces **64-bit High-Capacity (HC) counters**:
* **Inbound Bandwidth (bps):** `1.3.6.1.2.1.31.1.1.1.6.{#SNMPINDEX}` (`ifHCInOctets`)
* **Outbound Bandwidth (bps):** `1.3.6.1.2.1.31.1.1.1.10.{#SNMPINDEX}` (`ifHCOutOctets`)
* **Preprocessing:** `Change per second` $	imes 8$ (converts byte deltas to bits per second).

---

## 5. Enterprise Alerting Triggers & Thresholds

Automated alerting triggers are engineered to prevent alert fatigue while catching critical degradations before users report outages:

| Priority | Trigger Name | Evaluation Expression (Zabbix Syntax) | Operational Impact |
| :--- | :--- | :--- | :--- |
| **DISASTER** | **Core Uplink Interface Down** | `last(/Cisco IOS SNMP/net.if.status[ifOperStatus.{#SNMPINDEX}])=2 and {$IFCONTROL}=1` | Critical trunk or WAN link offline. Redundancy lost. |
| **HIGH** | **Interface Discards / Packet Loss** | `min(/Cisco IOS SNMP/net.if.in.discards[ifInDiscards.{#SNMPINDEX}],5m) > 2` | Indicates duplex mismatch, damaged patch cable, or buffer exhaustion. |
| **HIGH** | **Bandwidth Saturation (>85%)** | `min(/Cisco IOS SNMP/net.if.in[ifHCInOctets.{#SNMPINDEX}],10m) > (0.85 * last(/Cisco IOS SNMP/net.if.speed[ifHighSpeed.{#SNMPINDEX}]))` | Sustained link congestion. Traffic queueing and latency occurring. |
| **HIGH** | **OSPF / BGP Neighbor State Down** | `last(/Cisco IOS SNMP/cospfNbrState[{#SNMPINDEX}]) < 8` | Dynamic routing adjacency dropped. Possible routing loop or failover. |
| **AVERAGE** | **CPU Utilization Spikes (>90%)** | `min(/Cisco IOS SNMP/system.cpu.util[cpmCPUTotal5minRev.{#SNMPINDEX}],10m) > 90` | Control plane strain (broadcast storm, routing flap, or denial of service). |

---

## 6. Verification & CLI Diagnostic Testing

### 1. Validating Encrypted SNMPv3 Connectivity from Linux Poller
```bash
# Execute authenticated, encrypted SNMPv3 walk against Cisco CORE-SW01
snmpwalk -v3 -l authPriv     -u zabbix-poller     -a SHA-256 -A "AuthSecretPass2026!"     -x AES -X "PrivSecretPass2026!"     10.10.10.1 1.3.6.1.2.1.1.1.0
```
**Expected Output:**
```text
SNMPv2-MIB::sysDescr.0 = STRING: Cisco IOS Software, Catalyst L3 Switch Software (VIOS_L2-ADVENTERPRISEK9-M), Experimental Version 15.2
```

### 2. Wireshark Deep Packet Inspection Proof (Privacy Verification)
When inspecting the raw UDP 161 packet in Wireshark:
* **Protocol:** `SNMP`
* **SNMP Version:** `3`
* **Security Model:** `USM` (User-based Security Model)
* **Flags:** `0x03` (Authentication + Privacy flags both set)
* **Encrypted PDU:** `<Data is fully obfuscated / unreadable ciphertext>`  
*(Proves compliance with zero-trust network data-in-transit encryption standards).*

---

## 7. Author & Copyright Notice

Authored and copyrighted © 2026 Philippe Truong. All rights reserved.  
All architecture topologies, design documentation, and implementation guides are the property of Philippe Truong.
