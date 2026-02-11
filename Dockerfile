FROM node:22-bookworm

# Install Bun (required for build scripts)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

# Install VNC and Browser dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    chromium \
    fluxbox \
    fonts-liberation \
    fonts-noto-color-emoji \
    git \
    jq \
    novnc \
    python3 \
    socat \
    websockify \
    x11vnc \
    xvfb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN chmod +x ./scripts/start-vnc.sh


RUN pnpm install --no-frozen-lockfile

COPY . .
RUN chmod +x ./scripts/start-vnc.sh
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Create directories for mounted volumes and runtime data with correct ownership
# These directories are needed by:
# - /home/node/.openclaw: Main config/state directory
# - /home/node/.openclaw/cron: Cron job storage
# - /home/node/.openclaw/credentials: OAuth and auth tokens
# - /home/node/.openclaw/sessions: Active session state
# - /home/node/openclaw: Workspace root
# - /home/node/openclaw/canvas: Canvas host files
# - /tmp/openclaw: Runtime logs
RUN mkdir -p \
    /home/node/.openclaw/cron \
    /home/node/.openclaw/credentials \
    /home/node/.openclaw/sessions \
    /home/node/.openclaw/extensions \
    /home/node/openclaw/canvas \
    /tmp/openclaw && \
    chown -R node:node /home/node/.openclaw /home/node/openclaw /tmp/openclaw && \
    ln -s /app/dist/entry.js /usr/local/bin/moltbot && \
    ln -s /app/dist/entry.js /usr/local/bin/openclaw && \
    chmod +x /app/dist/entry.js

# Security hardening: Run as non-root user
# The node:22-bookworm image includes a 'node' user (uid 1000)
# This reduces the attack surface by preventing container escape via root privileges
USER node

CMD ["node", "dist/index.js"]
