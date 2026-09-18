#!/bin/bash
# ==============================================================================
# Linux Host SNMP Daemon & Custom Trap Generator for SolarWinds NPM
# Host: box (TinyCore / Linux Workload) | IP: 10.10.10.21/24 | GW: 10.10.10.1
# NMS: Windows Server 2022 / SolarWinds NPM (192.168.3.12)
# Author: Philippe Truong
# ==============================================================================

# 1. /usr/local/etc/snmp/snmpd.conf configuration for SolarWinds polling & traps
cat << 'EOF' > /usr/local/etc/snmp/snmpd.conf
# System Information
syslocation Lab Workload Tier (VLAN 10)
syscontact Philippe Truong (NetOps)

# Listening address on all interfaces, UDP port 161
agentAddress udp:161

# SNMPv2c Community for SolarWinds NMS
rocommunity SolarReadOnly

# Forward traps directly to SolarWinds NMS Server (UDP 162)
trap2sink 192.168.3.12 SolarReadOnly 162
EOF

# Restart Net-SNMP daemon
# /usr/local/etc/init.d/snmp start

# ==============================================================================
# 2. Custom SNMP Trap and Inform Simulation Commands
# ==============================================================================

echo "=== Sending SNMPv2c Trap to SolarWinds (UDP 162) ==="
# Sends a linkDown simulation trap
snmptrap -v 2c -c SolarReadOnly 192.168.3.12:162 '' 1.3.6.1.6.3.1.1.5.3 \
  1.3.6.1.2.1.2.2.1.1.2 i 2 \
  1.3.6.1.2.1.2.2.1.7.2 i 2 \
  1.3.6.1.2.1.2.2.1.8.2 i 2

echo "=== Sending Reliable SNMPv2c INFORM to SolarWinds ==="
# Sends an acknowledged inform (requires ACK from SolarWinds Trap Service)
snmpinform -v 2c -c SolarReadOnly 192.168.3.12:162 '' 1.3.6.1.4.1.2021.251.1 \
  1.3.6.1.2.1.1.5.0 s "Linux-Workload High Memory Threshold Exceeded"
