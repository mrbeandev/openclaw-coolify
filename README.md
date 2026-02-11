# 🦞 OpenClaw Coolify — Agentic AI Gateway

A premium, containerized deployment of the OpenClaw Agentic AI Gateway, optimized for **Coolify**.

## 📋 Prerequisites

Before you begin, ensure you have the following:

1. **Coolify Instance**: A running instance of Coolify.
2. **Domain Name**: A domain (or subdomain) pointed to your Coolify server.
   - _This is mandatory for the Gateway WebUI and secure communication._
3. **SSL Certificate**: Recommended (handled automatically by Coolify once a domain is pointed).

---

## 🚀 Setup Instructions

### Phase 0: Create Your Bot (Telegram or Discord)

**For Telegram:**

1. Open Telegram and search for **[@BotFather](https://t.me/BotFather)**.
2. Send `/newbot` and follow the prompts.
3. **Copy the API Token** (`TELEGRAM_BOT_TOKEN`).

**For Discord:**

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications).
2. Create a **New Application** and navigate to the **Bot** tab.
3. Reset/Copy your **Bot Token** (`DISCORD_BOT_TOKEN`).
4. Enable **Message Content Intent** in the "Privileged Gateway Intents" section.

> [!TIP]
> **More Channels**: OpenClaw also supports Slack, Signal, iMessage, and more. For advanced setup of other channels, refer to the [Official Documentation](https://docs.openclaw.ai/channels).

### Phase 1: Coolify Deployment

1. **Open Coolify Instance**: Log in to your Coolify dashboard.
2. **Navigate to Projects**: Click on the "Projects" tab.
3. **Click on [+ Add]**: Create a new project for your bot.
4. **Enter Project Name**: Give it a name (e.g., `openclaw`).
5. **Click Continue**: Proceed to the resource selection.
6. **Click on [+ Add Resources]**: Select the type of resource to add.
7. **Select Public Repository**: Choose "Public Repository" as the source.
   > **Note**: After this step, some users might see options to select a destination; ensure you select the correct one.
8. **Enter URL**: Provide the repository URL: `https://github.com/mrbeandev/openclaw-coolify` and click on **[ Check Repository ]**.
9. **Select Build Pack**: Click on **NixPack**, select **docker-compose**, and click **Continue**.
10. **Configure Environment Variables**: In the configuration page, go to the **Environment Variables** section and set these variables:

| Variable                 | Description                             | Required |
| :----------------------- | :-------------------------------------- | :------: |
| `OPENCLAW_GATEWAY_TOKEN` | Your custom "Password" for the WebUI.   |    ✅    |
| `TELEGRAM_BOT_TOKEN`     | The token from @BotFather.              |   ❌\*   |
| `DISCORD_BOT_TOKEN`      | The token from Discord Portal.          |   ❌\*   |
| `GEMINI_API_KEY`         | Used for long-term memory (embeddings). |    ❌    |

_\* At least one channel token (Telegram or Discord) is required for the bot to be accessible._

> [!IMPORTANT]
> **How to set `OPENCLAW_GATEWAY_TOKEN`**:
> This is **NOT** a token you get from a website. It is a secret password **YOU create** to secure your gateway for the initial login.
>
> 1. Think of a long, random string (e.g., `MySuperSecret123!_RandomString`).
> 2. Or generate one in your terminal: `openssl rand -base64 32`.
> 3. Paste it into Coolify and **SAVE IT**—you will need it for the initial setup. After deployment, the `openclaw dashboard` command (Phase 3) is the easiest way to get a login link.

> [!TIP]
> **Gemini API Key**: If you skip the `GEMINI_API_KEY` in the environment variables, you can still configure it later in the terminal. It is primarily used for the **Long-Term Memory** (embeddings) feature.

> [!NOTE]
> `OPENCLAW_GATEWAY_PASSWORD` is optional but recommended for extra security.

11. **Configure Your Domain**: In the **General** tab:
    - **Manual**: Enter your custom domain (e.g., `https://openclaw.yourdomain.com`).
    - **Automatic**: If your Coolify instance is setup with a base domain, you can simply click the **[ Generate Domain ]** button to automatically create a subdomain for your bot.
    - _This step is mandatory for the WebUI and SSL to work._

🚀 **Finally, click on Deploy!**

---

## 🛠️ Phase 2: Onboarding

Once the service is running, open the **Terminal** for your `openclaw` container in Coolify and run:

```bash
openclaw onboard
```

_This command will guide you through setting up your identity and configuring AI models._

---

## 🌐 Phase 3: Access the Dashboard

To access your Gateway WebUI, you must generate a tokenized login link. Run this command in your Coolify instance terminal:

```bash
openclaw dashboard --no-open
```

1. **Copy the tokenized URL** printed in the terminal (specifically the one starting with `http://localhost:18789/?token=...`).
2. **Replace `localhost`** with your actual domain (e.g., `https://openclaw.yourdomain.com/?token=...`).
3. **Paste it into your browser**.

### 🔑 Authentication & Device Approval:

1. **Password Security**: If you set an `OPENCLAW_GATEWAY_PASSWORD` in Coolify, navigate to the **Overview** tab, enter it in the **Password** field, and click **Connect**.
2. **Approve Device**: On your first login, you must approve your browser device. Run these commands in your Coolify terminal:
   ```bash
   openclaw devices list
   openclaw devices approve <request_id>
   ```
   _Example: `openclaw devices approve 22d73fae-22f9-46ec-a566-b722fb0fcd9b`_

---

## 🖥️ Phase 4: Browser & VNC Access

Your bot now comes with a fully integrated **Headless Browser (Chromium)** and **VNC Server** running right inside the container! This allows the AI to browse the web visually, and allows **YOU** to watch and interact with it in real-time.

### 🔗 Accessing the Browser (noVNC)

You can view the browser session directly from your web browser using the built-in noVNC client.

**1. Create a Domain (Recommended):**

- Go to your Coolify resource settings.
- Add a new domain pointing to port `6080` (e.g., `https://vnc.your-domain.com`).
- Save and access the URL.

**2. Direct IP Access:**

- Access `http://<your-server-ip>:6080/vnc.html`
- _Note: Requires port `6080` to be open in your firewall._

### 🔐 VNC Credentials

- **Password**: `openclaw` (default)
  - You can change this by setting the `VNC_PASSWORD` environment variable in Coolify.

### 🤖 AI Control

The bot is automatically configured to use this browser. It can open tabs, click elements, and you can see it all happening live!

### ⚠️ Security Warnings & Threats

- **Weak Passwords**: The default VNC password is `openclaw`. **CHANGE THIS** immediately in your Coolify environment variables (`VNC_PASSWORD`).
- **Firewall Exposure**: If using direct IP access (`http://ip:6080`), you are bypassing some security layers. Ensure you restrict access to your IP only via firewall rules (e.g., AWS Security Groups, UFW).
- **Public Access**: Never expose the VNC port (6080) to the public internet without a strong password or VPN. Anyone with access can view the screen and control the mouse/keyboard.
- **Sensitive Data**: Avoid using the bot to log into highly sensitive personal banking or primary email accounts unless you have secured the VNC connection. The VNC stream is viewable by anyone with the password.

---

## 📱 Telegram / Discord Setup

### Channel Pairing (Telegram / Discord)

When you first message your bot on Telegram or Discord, it will respond with a message like this:

> **OpenClaw: access not configured.**
>
> Your Discord user id: `589741852224126976`
>
> Pairing code: `PMTNLQJZ`
>
> Ask the bot owner to approve with:
> `openclaw pairing approve discord <code>`

**To Approve Pairing:**

1. Open your Gateway WebUI (from Phase 3).
2. Go to the **Chat** section.
3. Paste the pairing command directly:
   `openclaw pairing approve discord PMTNLQJZ`
   _(Replace `discord` with `telegram` if needed, and use your actual code)._

---

## 📂 Data Persistence

Your data is persisted in two Docker volumes:

- `clawdbot_config`: Stores identity and config (`/home/node/.openclaw`)
- `clawdbot_workspace`: Stores agent files and history (`/home/node/clawd`)

---

## ⚡ Power Up Your Bot

Want to add more capabilities to your OpenClaw bot? Check out my collection of pre-built skills:

✨ **Explore My Skills**: [clawhub.ai/u/mrbeandev](https://clawhub.ai/u/mrbeandev)

---

_For the original OpenClaw documentation, see [default.readme.md](default.readme.md)._
