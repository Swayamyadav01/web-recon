# Web-Recon

Web-Recon is a comprehensive bash-based reconnaissance automation framework that streamlines the asset discovery and vulnerability assessment process for security professionals and bug bounty hunters. This tool orchestrates over 20+ open-source security tools to provide thorough reconnaissance capabilities across multiple attack vectors.

### Core Capabilities
Web-Recon excels in automated discovery and vulnerability detection across several key areas:

**Asset Discovery & Enumeration**
- Subdomain enumeration using 20+ tools including subfinder, amass, and chaos
- Certificate transparency monitoring through multiple CT log sources  
- DNS enumeration with advanced bruteforcing and permutation techniques
- Port scanning with naabu, masscan, and nmap integration
- Virtual host discovery and web technology fingerprinting
  
**Vulnerability Detection**
- Cross-Site Scripting (XSS) detection with multiple payload sets
- SQL injection testing through automated parameter fuzzing
- Local File Inclusion (LFI) and Remote Code Execution (RCE) checks
- Subdomain takeover vulnerability scanning
- Open redirect detection and validation
- Exposed .git directories and sensitive file discovery

  ##Installation
  ### Using Git Clone
```
git clone https://github.com/Swayamyadav01/web-recon.git
cd web-recon
docker-compose up --build
python3 run.py
Access the tool at: http://127.0.0.1:5000
```
