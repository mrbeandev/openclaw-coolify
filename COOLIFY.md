# 🚀 Deploying OpenClaw on Coolify

This repository is optimized for deployment on [Coolify](https://coolify.io). It includes a pre-configured `docker-compose.yml` and `Dockerfile` that handles everything from Traefik routing to automatic state migrations.

## 📦 Quick Setup

1.  **Create a New Service** in Coolify.
2.  **Select "Docker Compose"** and point it to this repository.
3.  **Add your Environment Variables** (see list below).
4.  **Deploy!**

## 🔑 Required Environment Variables

Add these variables in the Coolify dashboard to get started:

| Variable | Example Value | Description |
| :--- | :--- | :--- |
| `OPENCLAW_GATEWAY_TOKEN` | `your-secure-token` | The token used to authenticate your CLI and Dashboard. |
| `OPENCLAW_GATEWAY_PASSWORD` | `your-password` | Password for the web dashboard. |
| `OPENCLAW_AGENT_MODEL` | `google/gemini-3-flash-preview` | The primary AI model to use. |
| `GEMINI_API_KEY` | `AIza...` | Your Google AI Studio key. |
| `OPENCLAW_PUBLIC_URL` | `https://your-bot.example.com` | Your public FQDN (required for webhooks). |
| `OPENCLAW_CONTROL_UI_ALLOW_INSECURE_AUTH` | `true` | Allows logging into the dashboard from any browser. |

### 🛠️ Optional Keys
*   `BRAVE_API_KEY`: Enables web search capabilities.
*   `OPENROUTER_API_KEY`: Use models from OpenRouter.
*   `ZAI_API_KEY`: Use specialized ZAI models.
*   `OPENCLAW_DOCKER_APT_PACKAGES`: A space-separated list of Linux packages to install inside the container (e.g., `ffmpeg python3`).

## 💾 Persistent Storage

The project uses two managed volumes in Coolify:
*   `clawdbot_config`: Stores your `openclaw.json`, credentials, and system state.
*   `clawdbot_workspace`: Stores the AI's files, skills, and memory.

**Note:** If you are migrating from an older version, simply name your volumes `clawdbot_config` and `clawdbot_workspace` in Coolify, and the system will automatically migrate the internal paths to the new OpenClaw standard.

## 🏥 Health Checks

A built-in health check is included in the `docker-compose.yml`. Coolify/Traefik will automatically wait for the dashboard to be responsive before routing traffic to your instance.

## 🦞 Commands

To interact with your bot once it's running:
1.  Open the **Server Terminal** in Coolify.
2.  Find your container name (usually `openclaw`).
3.  Run commands like:
    ```bash
    docker exec -it openclaw moltbot status
    ```

---
Happy assistant building! 🦞
