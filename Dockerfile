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

RUN pnpm install --no-frozen-lockfile

COPY . .
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build
# Force pnpm for UI build (Bun may fail on ARM/Synology architectures)
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production

# Create directories for mounted volumes and runtime data with correct ownership
# These directories are needed by:
# - /home/node/.clawdbot: Main config/state directory
# - /home/node/.clawdbot/cron: Cron job storage
# - /home/node/.clawdbot/credentials: OAuth and auth tokens
# - /home/node/.clawdbot/sessions: Active session state
# - /home/node/clawd: Workspace root
# - /home/node/clawd/canvas: Canvas host files
# - /tmp/moltbot: Runtime logs
RUN mkdir -p \
    /home/node/.clawdbot/cron \
    /home/node/.clawdbot/credentials \
    /home/node/.clawdbot/sessions \
    /home/node/.clawdbot/extensions \
    /home/node/clawd/canvas \
    /tmp/moltbot && \
    chown -R node:node /home/node/.clawdbot /home/node/clawd /tmp/moltbot && \
    ln -s /app/dist/entry.js /usr/local/bin/moltbot && \
    ln -s /app/dist/entry.js /usr/local/bin/clawdbot && \
    chmod +x /app/dist/entry.js

# Security hardening: Run as non-root user
# The node:22-bookworm image includes a 'node' user (uid 1000)
# This reduces the attack surface by preventing container escape via root privileges
USER node

CMD ["node", "dist/index.js"]
