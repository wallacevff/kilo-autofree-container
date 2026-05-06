FROM node:22-bookworm

# 🔧 Instala pacotes + sudo
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
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
    sudo \
 && apt-get install -y --only-upgrade libnss3 sudo util-linux \
 && if dpkg-query -W -f='${Package}\n' 'cups*' 2>/dev/null | grep -q .; then apt-get purge -y 'cups*'; fi \
 && if dpkg-query -W -f='${Package}\n' systemd 2>/dev/null | grep -q '^systemd$'; then apt-get purge -y systemd systemd-sysv systemd-timesyncd; fi \
 && if [ -f /usr/bin/chfn ]; then chmod u-s /usr/bin/chfn; fi \
 && if [ -f /usr/bin/chsh ]; then chmod u-s /usr/bin/chsh; fi \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

# 🔥 Shell correto pro Kilo
ENV SHELL=/bin/bash
ENV HOME=/workspace
ENV BASH_ENV=/workspace/.bashrc

# 📦 Instala Kilo
RUN npm install -g @kilocode/cli

# 🔐 Permissões e sudo
RUN usermod -aG root node \
    && usermod -aG sudo node \
    && usermod -d /workspace node \
    && echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node \
    && chmod 0440 /etc/sudoers.d/node

# 📁 Workspace
COPY .bashrc /workspace/.bashrc
COPY .bashrc /root/.bashrc
COPY .bashrc /home/node/.bashrc
COPY kilo-csp-proxy.js /usr/local/bin/kilo-csp-proxy.js
COPY kilo-entrypoint.sh /usr/local/bin/kilo-entrypoint.sh

RUN chmod +x /usr/local/bin/kilo-entrypoint.sh \
    && ln -s /usr/local/bin/kilo /bin/kilo \
    && mkdir -p /workspace \
    && chown -R node:node /workspace /home/node/.bashrc

USER node

# 🌐 Porta
EXPOSE 4096
WORKDIR /workspace

# 🚀 Start
ENTRYPOINT ["/usr/local/bin/kilo-entrypoint.sh"]
