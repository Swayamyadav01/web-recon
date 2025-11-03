FROM python:3.11-slim

# Build args
ARG INSTALL_GRAPHQLMAP=true

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    GOLANG_VERSION=1.21.5 \
    PATH="/usr/local/go/bin:/root/go/bin:/opt/tools/bin:$PATH" \
    GOPATH="/root/go" \
    NODE_VERSION=20 \
    CHROMIUM_FLAGS="--no-sandbox --headless --disable-gpu" \
    FLASK_DEBUG=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git build-essential ca-certificates unzip \
    dnsutils nmap iproute2 net-tools iputils-ping \
    chromium chromium-driver xvfb \
    python3-dev python3-pip python3-venv \
    jq gawk perl libxml2-dev libxslt-dev \
    aria2 libcurl4-openssl-dev libssl-dev \
    libncurses5-dev libncursesw5-dev libreadline-dev \
    libtinfo-dev libffi-dev zlib1g-dev \
    libpcap-dev libpq-dev sqlite3 \
    ruby ruby-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Create directories
RUN mkdir -p /opt/tools/bin /opt/wordlists /usr/share/seclists/Discovery/DNS/ \
    /usr/share/seclists/Discovery/Web-Content/ /root/nuclei-templates/ \
    /usr/share/dirb/wordlists/ /usr/share/dnsrecon/ /app/recon_results

# Install Go
RUN wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz && \
    rm go${GOLANG_VERSION}.linux-amd64.tar.gz

# Install essential wordlists
RUN cd /usr/share/seclists/Discovery/DNS/ && \
    wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt && \
    wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-110000.txt && \
    cd /usr/share/seclists/Discovery/Web-Content/ && \
    wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt && \
    wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-large-files.txt && \
    cd /usr/share/dirb/wordlists/ && \
    wget -q https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt && \
    cd /usr/share/dnsrecon/ && \
    echo -e "8.8.8.8\n1.1.1.1\n9.9.9.9\n8.8.4.4" > namelist.txt && \
    cd /opt/wordlists && \
    echo -e "/api\n/v1\n/v2\n/v3\n/graphql\n/swagger\n/docs" > api_wordlist.txt

WORKDIR /app

# Install Python dependencies with compatible versions
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Install additional Python security tools with compatible versions
RUN pip install --no-cache-dir \
    "requests>=2.25.0,<2.29.0" \
    "beautifulsoup4>=4.9.0" \
    "lxml>=4.6.0" \
    "python-nmap>=0.7.0" \
    "scapy>=2.4.0" \
    "paramiko>=2.7.0" \
    "cryptography>=3.4.0" \
    "dnspython>=2.1.0" \
    "tldextract>=3.1.0" \
    "colorama>=0.4.0" \
    "texttable>=1.6.0" \
    "selenium>=4.0.0" \
    "webdriver-manager>=3.5.0" \
    "pyopenssl>=20.0.0" \
    dnsgen arjun semgrep

# Install Go tools
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest && \
    go install -v github.com/tomnomnom/assetfinder@latest && \
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest && \
    go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest && \
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && \
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest && \
    go install -v github.com/projectdiscovery/katana/cmd/katana@latest && \
    go install -v github.com/sensepost/gowitness@latest && \
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest && \
    go install -v github.com/hahwul/dalfox/v2@latest && \
    go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest && \
    go install -v github.com/PentestPad/subzy@latest && \
    go install -v github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest && \
    go install -v github.com/d3mondev/puredns/v2@latest && \
    go install -v github.com/OJ/gobuster/v3@latest && \
    go install -v github.com/ffuf/ffuf/v2@latest && \
    go install -v github.com/gwen001/github-subdomains@latest && \
    go install -v github.com/tomnomnom/waybackurls@latest && \
    go install -v github.com/lc/gau/v2/cmd/gau@latest && \
    go install -v github.com/hakluke/hakrawler@latest && \
    go install -v github.com/tomnomnom/httprobe@latest && \
    go install -v github.com/projectdiscovery/notify/cmd/notify@latest && \
    go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest && \
    go install -v github.com/Brosck/mantra@latest && \
    go install -v github.com/hakluke/hakcheckurl@latest && \
    go install -v github.com/hakluke/hakrevdns@latest && \
    go install -v github.com/hakluke/haktldextract@latest

# Install Nikto
RUN cd /opt/tools && \
    git clone https://github.com/sullo/nikto.git && \
    cd nikto/program && \
    ln -s /opt/tools/nikto/program/nikto.pl /opt/tools/bin/nikto && \
    chmod +x /opt/tools/bin/nikto

# Install DIRB
RUN cd /opt/tools && \
    git clone https://github.com/v0re/dirb.git && \
    cd dirb && \
    chmod +x configure && \
    ./configure && \
    make && \
    mv dirb /opt/tools/bin/ && \
    mkdir -p /usr/share/dirb/wordlists && \
    cp wordlists/* /usr/share/dirb/wordlists/ 2>/dev/null || echo "DIRB wordlists copied"

# Install testssl.sh
RUN cd /opt/tools && \
    git clone --depth 1 https://github.com/drwetter/testssl.sh.git && \
    ln -s /opt/tools/testssl.sh/testssl.sh /opt/tools/bin/testssl && \
    chmod +x /opt/tools/bin/testssl

# Install masscan
RUN cd /opt/tools && \
    git clone https://github.com/robertdavidgraham/masscan.git && \
    cd masscan && \
    make && \
    mv bin/masscan /opt/tools/bin/

# Install Aquatone
RUN cd /opt/tools && \
    wget -q https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip && \
    unzip aquatone_linux_amd64_1.7.0.zip && \
    mv aquatone /opt/tools/bin/ && \
    chmod +x /opt/tools/bin/aquatone && \
    rm aquatone_linux_amd64_1.7.0.zip

# Install EyeWitness
RUN cd /opt/tools && \
    git clone https://github.com/FortyNorthSecurity/EyeWitness.git && \
    cd EyeWitness/Python/setup && \
    pip install -r requirements.txt && \
    ln -s /opt/tools/EyeWitness/Python/EyeWitness.py /opt/tools/bin/eyewitness && \
    chmod +x /opt/tools/bin/eyewitness

# Install Subjack
RUN cd /opt/tools && \
    git clone https://github.com/haccer/subjack.git && \
    cd subjack && \
    go mod init subjack 2>/dev/null || true && \
    go mod tidy 2>/dev/null || true && \
    go build -o subjack . && \
    mv subjack /opt/tools/bin/

# Install SubOver
RUN cd /opt/tools && \
    git clone https://github.com/Ice3man543/SubOver.git && \
    cd SubOver && \
    go mod init subover 2>/dev/null || true && \
    go mod tidy 2>/dev/null || true && \
    go build -o SubOver . && \
    mv SubOver /opt/tools/bin/

# Install GraphQLmap (can be skipped with --build-arg INSTALL_GRAPHQLMAP=false)
RUN val=$(printf "%s" "$INSTALL_GRAPHQLMAP" | tr '[:upper:]' '[:lower:]'); \
  if [ "$val" = "true" ] || [ "$val" = "1" ] || [ "$val" = "yes" ]; then \
    cd /opt/tools && \
    git clone https://github.com/swisskyrepo/GraphQLmap.git && \
    cd GraphQLmap && \
    # Remove PyPI 'readline' (not needed on Linux, breaks on Python 3.11)
    sed -i '/^readline\([[:space:]=<>].*\)\?$/d; /^readline$/d' requirements.txt || true && \
    python3 -m pip uninstall -y readline || true && \
    pip install -r requirements.txt || echo "GraphQLmap requirements install failed, continuing"; \
  else \
    echo "Skipping GraphQLmap installation"; \
  fi

# Install Dirsearch
RUN cd /opt/tools && \
    git clone https://github.com/maurosoria/dirsearch.git && \
    cd dirsearch && \
    pip install -r requirements.txt && \
    ln -s /opt/tools/dirsearch/dirsearch.py /opt/tools/bin/dirsearch && \
    chmod +x /opt/tools/bin/dirsearch

# Install JSParser
RUN cd /opt/tools && \
    git clone https://github.com/nahamsec/JSParser.git && \
    cd JSParser && \
    pip install -r requirements.txt && \
    if [ -f "jsparser.py" ]; then \
        ln -s /opt/tools/JSParser/jsparser.py /opt/tools/bin/jsparser && \
        chmod +x /opt/tools/bin/jsparser; \
    elif [ -f "JSParser.py" ]; then \
        ln -s /opt/tools/JSParser/JSParser.py /opt/tools/bin/jsparser && \
        chmod +x /opt/tools/bin/jsparser; \
    else \
        echo "JSParser main file not found, skipping symlink"; \
    fi

# Install Sublist3r
RUN cd /opt/tools && \
    git clone https://github.com/aboul3la/Sublist3r.git && \
    cd Sublist3r && \
    pip install -r requirements.txt && \
    ln -s /opt/tools/Sublist3r/sublist3r.py /opt/tools/bin/sublist3r && \
    chmod +x /opt/tools/bin/sublist3r

# Install Findomain
RUN cd /opt/tools && \
    wget -q https://github.com/Findomain/Findomain/releases/latest/download/findomain-linux.zip && \
    unzip findomain-linux.zip && \
    mv findomain /opt/tools/bin/ && \
    chmod +x /opt/tools/bin/findomain && \
    rm findomain-linux.zip

# Install Retire.js and Wappalyzer
RUN npm install -g retire wappalyzer-cli

# Install SQLMap
RUN cd /opt/tools && \
    git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git && \
    ln -s /opt/tools/sqlmap/sqlmap.py /opt/tools/bin/sqlmap && \
    chmod +x /opt/tools/bin/sqlmap

# Install SSRFMap
RUN cd /opt/tools && \
    git clone https://github.com/swisskyrepo/SSRFmap.git && \
    cd SSRFmap && \
    pip install -r requirements.txt

# Install Commix
RUN cd /opt/tools && \
    git clone https://github.com/commixproject/commix.git && \
    cd commix && \
    if [ -f "src/requirements.txt" ]; then \
        pip install -r src/requirements.txt; \
    elif [ -f "requirements.txt" ]; then \
        pip install -r requirements.txt; \
    else \
        echo "No requirements.txt found, installing known dependencies"; \
        pip install requests urllib3; \
    fi && \
    ln -s /opt/tools/commix/commix.py /opt/tools/bin/commix && \
    chmod +x /opt/tools/bin/commix

# Install Liffy
RUN cd /opt/tools && \
    git clone https://github.com/mzfr/liffy.git && \
    cd liffy && \
    pip install -r requirements.txt

# Install Oralyzer
RUN cd /opt/tools && \
    git clone https://github.com/r0075h3ll/Oralyzer.git && \
    cd Oralyzer && \
    pip install -r requirements.txt

# Install OWASP ZAP (optional)
RUN cd /opt/tools && \
    ZAP_VERSION="2.14.0" && \
    echo "Attempting to install OWASP ZAP version ${ZAP_VERSION}" && \
    if wget -q https://github.com/zaproxy/zaproxy/releases/download/v${ZAP_VERSION}/ZAP_${ZAP_VERSION}_Linux.tar.gz || \
       wget -q https://github.com/zaproxy/zaproxy/releases/download/${ZAP_VERSION}/ZAP_${ZAP_VERSION}_Linux.tar.gz; then \
        tar -xzf ZAP_${ZAP_VERSION}_Linux.tar.gz && \
        mv ZAP_${ZAP_VERSION} zaproxy && \
        rm ZAP_${ZAP_VERSION}_Linux.tar.gz && \
        ln -s /opt/tools/zaproxy/zap.sh /opt/tools/bin/zap && \
        chmod +x /opt/tools/bin/zap && \
        echo "ZAP installed successfully"; \
    else \
        echo "Warning: ZAP installation skipped - not critical for operation"; \
    fi

# Install shcheck
RUN cd /opt/tools && \
    git clone https://github.com/santoru/shcheck.git && \
    cd shcheck && \
    chmod +x shcheck.py && \
    ln -s /opt/tools/shcheck/shcheck.py /opt/tools/bin/shcheck

# Download and setup nuclei templates
RUN nuclei -update-templates || echo "Nuclei templates will be updated on first run"

# Set up additional wordlists
RUN mkdir -p /usr/share/wordlists && \
    ln -s /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt /usr/share/wordlists/subdomains-top1million-5000.txt

# Handle resolvers file
RUN echo -e "1.1.1.1\n8.8.8.8\n9.9.9.9\n8.8.4.4\n1.0.0.1" > /app/resolvers.txt

# Set proper permissions
RUN find /opt/tools/bin -type f -executable -exec chmod +x {} \; 2>/dev/null || true && \
    chmod 755 /app && \
    chmod -R 755 /app/recon_results

# Copy application files
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# Expose port
EXPOSE 5000

# Initialize nuclei templates and start the application
CMD ["/bin/bash", "-c", "nuclei -update-templates -silent || echo 'Nuclei update failed'; echo '🚀 Security tools initialized'; python run.py"]
