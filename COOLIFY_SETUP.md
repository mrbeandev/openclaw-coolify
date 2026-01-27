# 🦞 Moltbot Coolify Setup — Gemini & Telegram

This file contains instructions for setting up Moltbot with Gemini and Telegram on your Coolify instance.

## ⚙️ Environment Variables

Add these to the **Environment Variables** tab in your Coolify service settings:

| Variable | Value |
| :--- | :--- |
| `CLAWDBOT_GATEWAY_TOKEN` | `REDACTED_GATEWAY_TOKEN` |
| `GEMINI_API_KEY` | `REDACTED_GEMINI_API_KEY` |
| `CLAWDBOT_AGENT_MODEL` | `google/gemini-3-flash-preview` |
| `CLAWDBOT_GATEWAY_PASSWORD` | `REDACTED_PASSWORD` |
| `CLAWDBOT_GATEWAY_PORT` | `18789` |
| `CLAWDBOT_GATEWAY_BIND` | `lan` |

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
