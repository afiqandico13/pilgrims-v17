# 📦 Modules Reference

## Overview

PILGRIMS v17.0 includes **18 security modules** covering all major security domains. Each module is designed to provide comprehensive security assessment for its specific domain.

---

## Module List

### 1. Web Application Security
**Module:** `module-web`  
**Command:** `./pilgrims.sh --module=web <target>`

**Description:** Comprehensive web application security testing including vulnerability scanning, security headers analysis, and OWASP Top 10 coverage.

**Features:**
- SQL Injection detection
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Security headers analysis
- SSL/TLS configuration
- Directory enumeration
- Technology detection

**Usage:**
```bash
./pilgrims.sh --module=web example.com --quick
./pilgrims.sh --module=web example.com --deep
./pilgrims.sh --module=web example.com --bug-bounty
```

---

### 2. Network Security Assessment
**Module:** `module-network`  
**Command:** `sudo ./pilgrims.sh --module=network <target>`

**Description:** Network infrastructure security assessment including port scanning, service detection, and vulnerability identification.

**Features:**
- Host discovery
- Port scanning
- Service enumeration
- OS detection
- Vulnerability scanning
- Network mapping

**Usage:**
```bash
sudo ./pilgrims.sh --module=network 192.168.1.0/24 --quick
sudo ./pilgrims.sh --module=network 192.168.1.0/24 --deep
```

---

### 3. Mobile App Security
**Module:** `module-mobile`  
**Command:** `./pilgrims.sh --module=mobile <file>`

**Description:** Mobile application security testing for Android and iOS platforms.

**Features:**
- APK/IPA analysis
- Manifest/Info.plist review
- Permission analysis
- Hardcoded secrets detection
- Certificate pinning check
- IPC testing

**Usage:**
```bash
./pilgrims.sh --module=mobile app.apk --android
./pilgrims.sh --module=mobile app.ipa --ios
```

---

### 4. Cloud Security
**Module:** `module-cloud`  
**Command:** `./pilgrims.sh --module=cloud [options]`

**Description:** Cloud infrastructure security assessment for AWS, Azure, and GCP.

**Features:**
- IAM analysis
- Storage security
- Compute security
- Network security
- Configuration audit
- Compliance check

**Usage:**
```bash
./pilgrims.sh --module=cloud --aws
./pilgrims.sh --module=cloud --azure
./pilgrims.sh --module=cloud --gcp
```

---

### 5. Active Directory Security
**Module:** `module-ad`  
**Command:** `./pilgrims.sh --module=ad <dc-ip>`

**Description:** Active Directory security assessment including enumeration, policy analysis, and vulnerability detection.

**Features:**
- User enumeration
- Group policy analysis
- Password policy check
- Kerberos testing
- Delegation analysis
- ACL auditing

**Usage:**
```bash
./pilgrims.sh --module=ad 192.168.1.10 --domain=corp.local --user=auditor --pass=Password123
```

---

### 6. Container & Kubernetes Security
**Module:** `module-container`  
**Command:** `./pilgrims.sh --module=container [options]`

**Description:** Container and Kubernetes security assessment.

**Features:**
- Docker security
- Image vulnerability scanning
- Kubernetes configuration
- RBAC analysis
- Network policies
- Pod security

**Usage:**
```bash
./pilgrims.sh --module=container --docker
./pilgrims.sh --module=container --k8s
```

---

### 7. Source Code Review (SAST)
**Module:** `module-code`  
**Command:** `./pilgrims.sh --module=code <path>`

**Description:** Static application security testing for source code.

**Features:**
- Vulnerability detection
- Secret scanning
- Dependency analysis
- Code quality check
- Security best practices

**Usage:**
```bash
./pilgrims.sh --module=code /path/to/source --lang=python
./pilgrims.sh --module=code /path/to/source --lang=javascript
```

---

### 8. Wireless Security
**Module:** `module-wireless`  
**Command:** `sudo ./pilgrims.sh --module=wireless <interface>`

**Description:** Wireless network security assessment.

**Features:**
- WiFi scanning
- Encryption analysis
- Rogue AP detection
- WPA cracking
- Bluetooth security

**Usage:**
```bash
sudo ./pilgrims.sh --module=wireless wlan0 --duration=120
sudo ./pilgrims.sh --module=wireless wlan0 --crack
```

---

### 9. Email Security
**Module:** `module-email`  
**Command:** `./pilgrims.sh --module=email <domain>`

**Description:** Email infrastructure security assessment.

**Features:**
- SPF/DKIM/DMARC analysis
- Email server security
- Phishing detection
- Header analysis

**Usage:**
```bash
./pilgrims.sh --module=email example.com
```

---

### 10. IoT/Firmware Security
**Module:** `module-iot`  
**Command:** `./pilgrims.sh --module=iot <target>`

**Description:** IoT device and firmware security assessment.

**Features:**
- Firmware analysis
- Binary extraction
- Vulnerability detection
- Default credentials
- Protocol analysis

**Usage:**
```bash
./pilgrims.sh --module=iot firmware.bin --firmware
./pilgrims.sh --module=iot 192.168.1.100 --device
```

---

### 11. Binary Analysis & Reverse Engineering
**Module:** `module-binary`  
**Command:** `./pilgrims.sh --module=binary <file>`

**Description:** Binary file analysis and reverse engineering.

**Features:**
- Static analysis
- Dynamic analysis
- String extraction
- Import/export analysis
- Packer detection

**Usage:**
```bash
./pilgrims.sh --module=binary malware.exe --static
./pilgrims.sh --module=binary malware.exe --dynamic
```

---

### 12. Blockchain & Web3 Security
**Module:** `module-blockchain`  
**Command:** `./pilgrims.sh --module=blockchain <target>`

**Description:** Blockchain and Web3 security assessment.

**Features:**
- Smart contract audit
- DeFi protocol security
- NFT security
- Wallet analysis
- Bridge security

**Usage:**
```bash
./pilgrims.sh --module=blockchain contract.sol --solidity
./pilgrims.sh --module=blockchain uniswap --defi
```

---

### 13. ICS/SCADA Security
**Module:** `module-ics`  
**Command:** `./pilgrims.sh --module=ics <target>`

**Description:** Industrial Control Systems security assessment.

**Features:**
- Protocol analysis (Modbus, DNP3)
- PLC security
- HMI security
- Safety system testing

**Usage:**
```bash
./pilgrims.sh --module=ics 192.168.1.100
```

---

### 14. Medical Device Security
**Module:** `module-medical`  
**Command:** `./pilgrims.sh --module=medical <target>`

**Description:** Medical device security assessment.

**Features:**
- DICOM security
- HL7 analysis
- Patient data protection
- FDA compliance

**Usage:**
```bash
./pilgrims.sh --module=medical 192.168.1.50
```

---

### 15. Financial Systems Security
**Module:** `module-financial`  
**Command:** `./pilgrims.sh --module=financial <target>`

**Description:** Financial systems security assessment.

**Features:**
- PCI-DSS compliance
- Payment security
- Transaction integrity
- Fraud detection

**Usage:**
```bash
./pilgrims.sh --module=financial payment_gateway
```

---

### 16. Automotive Security
**Module:** `module-automotive`  
**Command:** `./pilgrims.sh --module=automotive <target>`

**Description:** Automotive systems security assessment.

**Features:**
- CAN bus analysis
- OBD-II security
- Telemetry analysis
- Key fob security

**Usage:**
```bash
./pilgrims.sh --module=automotive can0
```

---

### 17. 5G/Telecom Security
**Module:** `module-5g`  
**Command:** `./pilgrims.sh --module=5g <target>`

**Description:** 5G and telecommunications security assessment.

**Features:**
- 5G protocol testing
- SIM card security
- IMSI catcher detection
- RF analysis

**Usage:**
```bash
./pilgrims.sh --module=5g gnb
```

---

### 18. Gaming Security
**Module:** `module-gaming`  
**Command:** `./pilgrims.sh --module=gaming <target>`

**Description:** Gaming and esports security assessment.

**Features:**
- Game client security
- Anti-cheat analysis
- Virtual economy audit
- Memory protection

**Usage:**
```bash
./pilgrims.sh --module=gaming game.exe
```

---

## Module Architecture

Each module follows a consistent structure:

```
modules/module-<name>/
├── pilgrims-<name>.sh    # Main module script
├── plugins/              # Module-specific plugins
├── reports/              # Generated reports
└── logs/                 # Module logs
```

## Module Integration

All modules integrate with:
- **Core UI** - Consistent banner and output formatting
- **Database** - Unified scan history and findings
- **Reporting** - Standard report formats
- **Logging** - Centralized logging system

## Creating Custom Modules

To create a custom module:

```bash
# Use plugin manager
./pilgrims-manage.sh create my-module

# Or manually create
mkdir -p modules/module-my-module/{plugins,reports,logs}
cat > modules/module-my-module/pilgrims-my-module.sh << 'EOF'
#!/bin/bash
# Custom module implementation
EOF
chmod +x modules/module-my-module/pilgrims-my-module.sh
```

---

**🏴‍☠️ Explore all modules, Captain!**
