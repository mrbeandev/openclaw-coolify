# 🚀 Hosting Clawdbot on Coolify

This project is fully optimized for [Coolify](https://coolify.io/). With the updated `docker-compose.yml`, you can deploy your own instance in minutes.

## 🛠️ Deployment Steps

1. **Fork this Repo**: Make sure you have this project in your own GitHub account.
2. **Create a New Service in Coolify**:
   - Choose **Docker Compose**.
   - Connect your GitHub repository.
3. **Configure Environment Variables**:
   In the Coolify dashboard, go to the **Environment Variables** tab and add:
   - `CLAWDBOT_GATEWAY_TOKEN`: A secure random password for your gateway.
   - `CLAUDE_AI_SESSION_KEY`: (Optional) Your Anthropic session key.
   - `CLAUDE_WEB_SESSION_KEY`: (Optional) Your Claude web session key.
   - `CLAUDE_WEB_COOKIE`: (Optional) Your Claude web cookie.
4. **Deploy**: Click the **Deploy** button.

## 📦 Persistent Storage
Coolify will automatically create and manage two volumes:
- `clawdbot_config`: Stores your credentials, settings, and sessions.
- `clawdbot_workspace`: Stores the files and data the bot works with.

## 🔒 Security & Sandboxing
If you want the bot to be able to run code in isolated Docker containers (Sandboxing):
1. In `docker-compose.yml`, uncomment the Docker socket mount and the `user: root` lines.
2. Add `docker.io` to a new environment variable `CLAWDBOT_DOCKER_APT_PACKAGES`.
3. Redeploy.

## 🧪 Post-Deployment
Once the gateway is running, you can access the Control UI at `http://your-server-ip:18789` (or your configured FQDN).

To link providers (WhatsApp, Telegram, etc.):
1. Access the container terminal via Coolify.
2. Run:
   ```bash
   node dist/index.js providers login
   ```
   Follow the interactive prompts to scan QR codes or enter tokens.

---
*Built with ❤️ for the Clawdbot community.*
