# ==============================================================================
# Script: dns_automation.ps1
# Lab 08: Enterprise Windows Server DNS Infrastructure
# Author: Philippe Truong
# Domain: corp.local | Primary DC: CORPDC01 (10.10.10.10)
# ==============================================================================

# 1. Configure Upstream DNS Forwarders (Google Public DNS & Cloudflare)
Write-Host "=== Configuring Upstream DNS Forwarders ===" -ForegroundColor Cyan
Set-DnsServerForwarder -IPAddress @("8.8.8.8", "8.8.4.4", "1.1.1.1") -PassThru

# 2. Create Active Directory-Integrated Reverse Lookup Zones
Write-Host "=== Creating Reverse Lookup Zones ===" -ForegroundColor Cyan
# Subnet 10.10.10.0/24 (Servers & Domain Controllers)
if (-not (Get-DnsServerZone -Name "10.10.10.in-addr.arpa" -ErrorAction SilentlyContinue)) {
    Add-DnsServerPrimaryZone -NetworkId "10.10.10.0/24" -ReplicationScope "Domain"
    Write-Host "Created Reverse Zone: 10.10.10.in-addr.arpa" -ForegroundColor Green
}

# Subnet 10.10.9.0/24 (Routers & Network Transit)
if (-not (Get-DnsServerZone -Name "9.10.10.in-addr.arpa" -ErrorAction SilentlyContinue)) {
    Add-DnsServerPrimaryZone -NetworkId "10.10.9.0/24" -ReplicationScope "Domain"
    Write-Host "Created Reverse Zone: 9.10.10.in-addr.arpa" -ForegroundColor Green
}

# 3. Create Host (A) Records
Write-Host "=== Creating Host (A) Records ===" -ForegroundColor Cyan
# Cisco Edge Router
Add-DnsServerResourceRecordA -ZoneName "corp.local" -Name "router" -IPv4Address "10.10.9.1" -CreatePtr -AllowUpdateAny

# 4. Create Reverse Pointer (PTR) Records
Write-Host "=== Creating Reverse Pointer (PTR) Records ===" -ForegroundColor Cyan
# Domain Controllers
Add-DnsServerResourceRecordPtr -ZoneName "10.10.10.in-addr.arpa" -Name "10" -PtrDomainName "corpdc01.corp.local." -AllowUpdateAny
Add-DnsServerResourceRecordPtr -ZoneName "10.10.10.in-addr.arpa" -Name "11" -PtrDomainName "corpdc02.corp.local." -AllowUpdateAny
# Cisco Edge Router
Add-DnsServerResourceRecordPtr -ZoneName "9.10.10.in-addr.arpa" -Name "1" -PtrDomainName "router.corp.local." -AllowUpdateAny

# 5. Create Canonical Name (CNAME) Aliases
Write-Host "=== Creating CNAME Alias Records ===" -ForegroundColor Cyan
# Generic DC Alias
Add-DnsServerResourceRecordCName -ZoneName "corp.local" -Name "dc" -HostNameAlias "corpdc01.corp.local."
# Generic LDAP Service Alias
Add-DnsServerResourceRecordCName -ZoneName "corp.local" -Name "ldap" -HostNameAlias "corpdc01.corp.local."
# Default Gateway Alias
Add-DnsServerResourceRecordCName -ZoneName "corp.local" -Name "gw" -HostNameAlias "router.corp.local."

# 6. Verification Queries
Write-Host "=== Verification: Forward & Reverse Resolutions ===" -ForegroundColor Cyan
Write-Host "Testing CNAME dc.corp.local:"
Resolve-DnsName -Name "dc.corp.local" | Format-Table -AutoSize

Write-Host "Testing Gateway CNAME gw.corp.local:"
Resolve-DnsName -Name "gw.corp.local" | Format-Table -AutoSize

Write-Host "Testing Reverse PTR for Router (10.10.9.1):"
Resolve-DnsName -Name "10.10.9.1" | Format-Table -AutoSize

Write-Host "Testing Active Directory SRV Discovery:"
Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.corp.local" -Type SRV | Format-Table -AutoSize
