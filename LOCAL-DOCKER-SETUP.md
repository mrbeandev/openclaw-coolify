# 🦞 Local Docker Setup & Distribution Guide

This guide explains how to run OpenClaw locally on your machine and how to safely share your custom version with friends.

## 💻 Running Locally

You can run your own instance of OpenClaw on Windows, macOS, or Linux.

### 1. Prerequisites
*   Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
*   Ensure Docker is running.

### 2. Configuration
1.  **Create your environment file**:
    ```bash
    cp .env.local.example .env
    ```
2.  **Edit `.env`**:
    Open the file in any text editor and fill in your API keys (e.g., `GEMINI_API_KEY`, `OPENCLAW_GATEWAY_TOKEN`).

### 3. Launch
Run the following command in your terminal:

```bash
docker compose up -d
```

*   The bot will build and start in the background.
*   Once running, open your dashboard at: **[http://localhost:18789](http://localhost:18789)**.

### 4. Updating
To update your local instance using our cool updater script:

```bash
./update.sh
```

---

## 🎁 Distributing to Friends

Since this project uses the **MIT License**, you are free to share, modify, and distribute this code to anyone.

### ✅ What to Share
You can zip up this folder or push it to a new GitHub repository. Ensure these files are included:
*   `docker-compose.yml`
*   `Dockerfile`
*   `update.sh`
*   `.env.local.example`
*   `README.md` / `LOCAL-DOCKER-SETUP.md`

### ⛔ What NOT to Share (Safety Check)
**Never** share these files or folders. They contain your secrets and your bot's personal memories.

1.  ❌ **`.env`**: Contains your private API keys and passwords. Your friends should create their own from `.env.local.example`.
2.  ❌ **`.openclaw/`**: Contains your bot's identity, sessions, and memory.
3.  ❌ **`clawd/` or `openclaw/`**: Workspace folders where the bot stores its files.

### 🚀 Quick Start for Friends
Just tell your friends to:
1.  Download your code.
2.  Create their own `.env` file with their keys.
3.  Run `docker compose up -d`.

They will get a fresh, blank-slate bot ready to be trained! 🦞
