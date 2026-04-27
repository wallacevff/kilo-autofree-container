FROM node:22

# 🔧 Instala só o necessário
RUN apt-get update && apt-get upgrade && apt-get install -y \
    bash \
    curl \
    git \
    iputils-ping \
    procps \
    ca-certificates \
    libssl3 \
    libsecret-1-0 \
    libx11-6 \
    libxcomposite1 \
    libxrandr2 \
    libxdamage1 \
    libxtst6 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnotify-dev \
    libnss3 \
    libxss1 \
    libasound2 \
    fonts-liberation \
    expect \
    util-linux \
    libc6 \
    libgcc-s1 \
    libstdc++6 \
 && rm -rf /var/lib/apt/lists/*


# 🔥 Shell correto pro Kilo
ENV SHELL=/bin/bash

# 📦 Instala Kilo
RUN npm install -g @kilocode/cli

# 📁 Workspace
WORKDIR /root/workspace
COPY .bashrc /root/.bashrc
COPY kilo-csp-proxy.js /usr/local/bin/kilo-csp-proxy.js
COPY kilo-entrypoint.sh /usr/local/bin/kilo-entrypoint.sh
RUN chmod +x /usr/local/bin/kilo-entrypoint.sh
RUN ln -s /usr/local/bin/kilo /bin/kilo
# 🌐 Porta
EXPOSE 4096

# 🚀 Start
ENTRYPOINT ["/usr/local/bin/kilo-entrypoint.sh"]
