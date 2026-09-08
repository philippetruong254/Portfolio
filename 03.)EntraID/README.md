# Microsoft Entra ID (formerly Azure AD): Core Concepts Reference

A conceptual guide for Windows Server administrators and network engineers bridging on-premises Active Directory to cloud identity.

```
+-----------------------------------------------------------------------------------------+
|                                    MICROSOFT ENTRA ID                                   |
|                          (Global Cloud Identity & Access Provider)                      |
|                                                                                         |
|       [ Cloud Applications ]          [ Office 365 / M365 ]         [ Enterprise SaaS ] |
|       (Azure Portal, APIs)            (Exchange, Teams, etc.)       (Salesforce, etc.)  |
|                 ^                               ^                             ^         |
|                 |                               |                             |         |
|                 +-------------------------------+-----------------------------+         |
|                                                 | (OAuth 2.0 / OIDC / SAML)             |
|                                                 |                                       |
|                                      [ CONDITIONAL ACCESS ]                             |
|                                 (The Security Decision Engine)                          |
|                                      * Is user trusted?                                 |
|                                      * Is device compliant?                             |
|                                      * Require MFA?                                     |
|                                                 |                                       |
+-------------------------------------------------+---------------------------------------+
                                                  ^
                                                  | (HTTPS Outbound Sync)
                                      +-----------+-----------+
                                      | Microsoft Entra       |
                                      | Connect (Sync Agent)  |
                                      +-----------+-----------+
                                                  |
                     +----------------------------+----------------------------+
                     | (Active Directory LDAP / RPC)                           |
                     v                                                         v
        [ On-Premises Domain Controller ]                         [ Azure IaaS Domain Controller ]
        - Houston DC-01 (10.10.10.10)                             - Cloud DC-03 (10.100.1.4)
        - Windows Server Active Directory                         - Replicated AD DS Forest
```

---

## 1. The Core Paradigm Shift: AD DS vs. Entra ID

Traditional Active Directory and Microsoft Entra ID are built for two entirely different eras of computing:

| Feature | Active Directory Domain Services (AD DS) | Microsoft Entra ID |
| :--- | :--- | :--- |
| **Environment** | On-premises networks, LANs, private WANs | The public web, cloud apps, mobile devices |
| **Protocols** | **Kerberos**, **NTLM**, **LDAP**, **SMB**, **RPC** | **OAuth 2.0**, **OpenID Connect (OIDC)**, **SAML 2.0**, **REST APIs** |
| **Structure** | Hierarchical: Forest $\rightarrow$ Domains $\rightarrow$ Organizational Units (OUs) | Flat: Tenants $\rightarrow$ Users & Security Groups (No OUs) |
| **Device Management**| Group Policy Objects (GPOs) | Microsoft Intune (MDM/MAM) |
| **Network Boundary**| Behind corporate perimeter firewalls | Zero Trust: Identity *is* the new security perimeter |

> [!NOTE]
> **Organizational Units (OUs)** do not exist in Entra ID. While Entra Connect can filter *which* on-prem OUs get synchronized, Entra ID stores all users in a flat tenant directory and organizes them using **Groups**, **Dynamic Groups**, and **Administrative Units (AUs)**.

---

## 2. Microsoft Entra Connect (The Hybrid Bridge)

**Microsoft Entra Connect** is the software agent installed on a Windows Server that reads your on-premises Active Directory and synchronizes user accounts, groups, and credentials to Entra ID.

### The 3 Credential Sync Methods:

#### 1. Password Hash Synchronization (PHS) — *(Recommended Best Practice)*
* **How it works**: Entra Connect takes a cryptographic hash of your on-premises password hash (a "hash-of-a-hash") and syncs it to Entra ID.
* **Why it's the standard**:
  * **Zero dependency on on-prem uptime**: If your office power fails or the VPN drops, users can still log in to Office 365 without interruption.
  * Enables **Leaked Credential Detection**: Microsoft can cross-check synced hashes against dark web password dumps and alert you if an employee’s password was compromised.

#### 2. Pass-Through Authentication (PTA)
* **How it works**: Passwords are *never* stored in the cloud. When a user logs in to Office 365, Entra ID sends a secure validation request down to an on-prem agent that tests the password against your local Domain Controller in real time.
* **Trade-off**: If your on-prem network or DCs go offline, cloud logins fail.

#### 3. Active Directory Federation Services (ADFS)
* **How it works**: Heavyweight on-prem server farm that redirects cloud logins back to an on-prem login page.
* **Status**: Legacy. Most organizations have migrated away from ADFS to PHS + Seamless SSO.

---

### Key Entra Connect Features for Admins:

* **Self-Service Password Reset (SSPR) with Password Writeback**:
  * Allows users to reset their forgotten password from a web browser (`passwordreset.microsoftonline.com`).
  * **Password Writeback** writes the new password back down into your on-premises Active Directory in real time.
* **Staging Mode (High Availability)**:
  * You can install a second Entra Connect server in **Staging Mode** (passive standby). It processes changes locally but does not export them to Entra ID. If the primary sync server fails, you promote the staging server to active.

---

## 3. Single Sign-On (SSO)

Single Sign-On ensures an employee enters their credentials **once** and gains access to all corporate resources without repeated password prompts.

### Types of SSO:
1. **Seamless SSO (Desktop SSO)**:
   * When an employee is sitting in the office on a domain-joined PC, Entra ID challenges the PC via Kerberos. The user opens their browser to Office 365 and is automatically signed in **without typing a username or password**.
2. **SAML 2.0 / OIDC SSO**:
   * Entra ID acts as the **Identity Provider (IdP)** for third-party cloud apps (e.g., Salesforce, ServiceNow, Zoom, AWS Console). Users click the app tile and sign in seamlessly using their corporate Entra identity.

---

## 4. Multi-Factor Authentication (MFA) & Conditional Access

In modern cloud security, passwords alone are never enough. Entra ID pairs MFA with an intelligent policy engine.

### What is MFA?
Requires two or more verification factors:
1. **Something you know**: Password or PIN.
2. **Something you have**: Microsoft Authenticator app (Number Matching push notifications), FIDO2 hardware security key, or SMS/Voice code.
3. **Something you are**: Biometrics (Windows Hello facial recognition or fingerprint).

---

### Conditional Access (The "Zero Trust" Brain)

**Conditional Access** is an automated "If-Then" policy engine that evaluates every single authentication attempt before granting access:

$$\text{Signals (If)} \longrightarrow \text{Decision} \longrightarrow \text{Enforcement (Then)}$$

```
               [ INCOMING SIGNALS ]
+--------------------------------------------------+
|  User & Group:   Finance Team                    |
|  Location:       Unknown Public IP / Foreign Country|
|  Device:         Non-Compliant / Personal Phone  |
|  Client App:     Legacy POP3 / IMAP              |
|  Risk Level:     Medium / High User Risk         |
+-------------------------+------------------------+
                          |
                          v
               [ CONDITIONAL ACCESS ENGINE ]
               "Does this request look safe?"
                          |
            +-------------+-------------+
            |                           |
            v                           v
     [ LOW RISK ]                [ SUSPICIOUS / UNKNOWN ]
     * Trusted IP                * Remote / Travel
     * Corporate Device          * New Device
            |                           |
            v                           v
    GRANT ACCESS                REQUIRE MFA or
                                BLOCK ACCESS
```

### Common Enterprise Conditional Access Policies:
1. **Require MFA for all Admins**: Any account with administrative roles must use MFA every time.
2. **Block Legacy Authentication**: Disables older protocols (POP3, IMAP, SMTP) that cannot prompt for modern MFA and are vulnerable to password spraying.
3. **Require Compliant Device**: Access to corporate data is only allowed from company-managed, encrypted laptops.
4. **Geo-Blocking / Named Locations**: Automatically blocks login attempts originating from countries where the company has no employees or business operations.

---

## 5. Device Identity States

Understanding how devices register in Entra ID is critical for network administrators:

| Device State | Ownership | Joined To | Management | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **Microsoft Entra Registered** | Personal | Not joined to any domain | Minimal / Mobile App Management (MAM) | BYOD (Employee personal iPhones, Androids, home PCs) |
| **Microsoft Entra Joined** | Corporate | Cloud-only (**Entra ID**) | Microsoft Intune | Modern cloud-first laptops (No on-prem DC connection needed) |
| **Microsoft Entra Hybrid Joined** | Corporate | **Both** On-Prem AD (`corp.local`) **and** Entra ID | Group Policy (GPO) + Intune | Traditional enterprise standard (Domain-joined PCs synced to cloud) |

---

## 6. Senior Admin Interview Quick-Card

* **Q: If our on-prem WAN connection drops, can users still log into Office 365?**
  * *A*: Yes, provided **Password Hash Synchronization (PHS)** is enabled. Entra ID authenticates users directly against cloud-stored hashes without needing to reach on-prem Domain Controllers.
* **Q: Can we run multiple active Entra Connect servers?**
  * *A*: No. You can only have **one active** sync engine per tenant. However, you can deploy a secondary server in **Staging Mode** for instant failover and disaster recovery.
* **Q: What is the difference between Security Defaults and Conditional Access?**
  * *A*: *Security Defaults* is a free, basic, one-click policy for small businesses (enforces MFA for all, cannot be customized). *Conditional Access* requires Entra ID P1/P2 licensing and provides granular, custom rules (locations, devices, risk levels).
* **Q: How does Password Writeback work?**
  * *A*: When a user resets their password in the cloud via Self-Service Password Reset (SSPR), the Entra Connect agent securely pushes that change back down over HTTPS to the on-prem Domain Controller, ensuring passwords stay identical everywhere.

---

## 7. Author & Copyright Notice

Authored and copyrighted © 2026 Philippe Truong. All rights reserved.  
All architecture topologies, design documentation, and implementation guides are the property of Philippe Truong.
