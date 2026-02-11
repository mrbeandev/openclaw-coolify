#!/bin/bash
set -e

# Defaults
VNC_PORT=${VNC_PORT:-5900}
NOVNC_PORT=${NOVNC_PORT:-6080}
CDP_PORT=${CDP_PORT:-9222}
VNC_PASSWORD=${VNC_PASSWORD:-openclaw}
DISPLAY_NUM=${DISPLAY_NUM:-1}
RESOLUTION=${RESOLUTION:-1600x900x24}

echo "Starting VNC/Browser environment..."
echo "  Display: :$DISPLAY_NUM ($RESOLUTION)"
echo "  VNC Port: $VNC_PORT"
echo "  noVNC Port: $NOVNC_PORT"
echo "  CDP Port: $CDP_PORT"

# 1. Start Xvfb
export DISPLAY=:$DISPLAY_NUM
rm -f /tmp/.X${DISPLAY_NUM}-lock /tmp/.X11-unix/X${DISPLAY_NUM}
Xvfb :$DISPLAY_NUM -screen 0 $RESOLUTION -ac -nolisten tcp > /dev/null 2>&1 &
XPID=$!
sleep 2

# 2. Start Window Manager (Fluxbox)
fluxbox > /dev/null 2>&1 &

# 3. Setup VNC Password
mkdir -p ~/.vnc
echo "$VNC_PASSWORD" | x11vnc -storepasswd pipe ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# 4. Start VNC Server (x11vnc)
x11vnc -display :$DISPLAY_NUM -rfbport $VNC_PORT -shared -forever -rfbauth ~/.vnc/passwd -bg -o ~/.vnc/x11vnc.log

# 5. Start noVNC (websockify)
# Check for websockify location (Debian usually /usr/bin/websockify)
if command -v websockify >/dev/null; then
    websockify --web /usr/share/novnc/ $NOVNC_PORT localhost:$VNC_PORT > /tmp/novnc.log 2>&1 &
else
    echo "WARNING: websockify not found, noVNC will not be available."
fi

# 6. Start Chromium (listening on CDP)
# We use --remote-debugging-port to allow OpenClaw to connect
chromium \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --remote-debugging-port=$CDP_PORT \
  --remote-debugging-address=127.0.0.1 \
  --no-first-run \
  --no-default-browser-check \
  --user-data-dir=$HOME/.config/chromium \
  --window-position=0,0 \
  --window-size=${RESOLUTION%x*} \
  about:blank > /tmp/chromium.log 2>&1 &

echo "Browser environment started."
echo "CDP endpoint: http://127.0.0.1:$CDP_PORT"

# 7. Configure OpenClaw to use this browser
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "{}" > "$CONFIG_FILE"
fi

# Use jq to update or add browser.cdpUrl
if command -v jq >/dev/null; then
  TMP_CONFIG=$(mktemp)
  jq --arg cdp "http://127.0.0.1:$CDP_PORT" '
    .browser = (.browser // {}) |
    .browser.cdpUrl = $cdp |
    .browser.enabled = true
  ' "$CONFIG_FILE" > "$TMP_CONFIG" && mv "$TMP_CONFIG" "$CONFIG_FILE"
  echo "Configured openclaw.json to use local CDP."
else
  echo "WARNING: jq not found, skipping openclaw.json update. Ensure browser.cdpUrl is set manually."
fi

# 8. Pass control to the main application
# We set OPENCLAW_BROWSER_CDP_URL env var if not set, so the app uses this browser
export OPENCLAW_BROWSER_CDP_URL=${OPENCLAW_BROWSER_CDP_URL:-http://127.0.0.1:$CDP_PORT}

exec "$@"
