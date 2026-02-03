# 🦞 Moltbot Coolify Setup — Gemini & Telegram

This file contains instructions for setting up Moltbot with Gemini and Telegram on your Coolify instance.

## ⚙️ Environment Variables

Add these to the **Environment Variables** tab in your Coolify service settings:

| Variable | Value |
| :--- | :--- |
| `CLAWDBOT_GATEWAY_TOKEN` | `n05QgrsNXlFmzJMcxxxxxxxxxxxxxxxxxzVj68JpCahFM4nrolucuoNb7` |
| `GEMINI_API_KEY` | `AIzaSyBZGlZ1xKePVTIRxxxxxxxxxxxxxxxxxxJS8` |
| `CLAWDBOT_AGENT_MODEL` | `google/gemini-3-flash-preview` |
| `CLAWDBOT_GATEWAY_PASSWORD` | `xxxxxxxxx` |
| `CLAWDBOT_GATEWAY_PORT` | `18789` |
| `CLAWDBOT_GATEWAY_BIND` | `lan` |

---

## 🌐 Gateway WebUI Setup

> ⚠️ **Requirement**: The Gateway WebUI will only work if you have pointed and connected a **domain** to your Coolify instance. Ensure your domain is properly configured before proceeding.

After deployment, access the Gateway WebUI at your configured port (default: `18789`).

### 1. Configure Gateway Token
1.  Navigate to **Overview** in the WebUI
2.  Enter your `CLAWDBOT_GATEWAY_TOKEN` in the **Gateway Token** input field
3.  The system will prompt you to **approve this device**

### 2. Approve Device Access
Open the **Terminal** for your `clawdbot` container in Coolify and run:

```bash
# List pending device requests
openclaw devices list

# Approve the device (replace <request_id> with actual ID from list)
openclaw devices approve <request_id>
```

### 3. (Optional) Add Antigravity Plugin
If you want to use Google Antigravity authentication:

```bash
# Enable the plugin
openclaw plugins enable google-antigravity-auth

# Login and set as default provider
openclaw models auth login --provider google-antigravity --set-default
```

---

## 🚀 Post-Deployment Setup

After you have successfully deployed the `clawdbot` service in Coolify, you must manually connect the Gemini model to your agent.

### 1. Connect the AI Model
Open the **Terminal** for your `clawdbot` container in the Coolify dashboard and run:

```bash
moltbot models set google/gemini-3-flash-preview
```

This command tells Moltbot to use your Gemini API key for all agent responses.

### 2. Verify Model Status
You can verify that the model is correctly configured and authenticated by running:

```bash
moltbot models status
```

---

## 📱 Telegram Pairing

If you are setting up Telegram for the first time or didn't migrate your database:

1.  **Start a Chat**: Message your bot on Telegram.
2.  **Get Pairing Code**: The bot will reply with a pairing code.
3.  **Approve Pairing**: In the Coolify terminal, run:
    ```bash
    moltbot pairing list telegram
    moltbot pairing approve telegram <YOUR_CODE>
    ```

## 📂 Migration
If you need to migrate your data from an old instance:
- `clawdbot_config` volume -> `/home/node/.clawdbot`
- `clawdbot_workspace` volume -> `/home/node/clawd`
