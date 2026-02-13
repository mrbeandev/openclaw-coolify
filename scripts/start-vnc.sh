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
# x11vnc -storepasswd expects [password] [file]
# We truncate to 8 chars because standard VNC auth is limited to 8 chars
# and mismatch between stored and typed password can cause issues.
VNC_PASS_SAFE=${VNC_PASSWORD:0:8}
x11vnc -storepasswd "$VNC_PASS_SAFE" ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# 4. Start VNC Server (x11vnc)
x11vnc -display :$DISPLAY_NUM -rfbport $VNC_PORT -shared -forever -rfbauth ~/.vnc/passwd -bg -o ~/.vnc/x11vnc.log

# 5. Apply noVNC branding (before starting websockify)
NOVNC_SRC="/usr/share/novnc"
NOVNC_DIR="/tmp/novnc-branded"
BRANDING_DIR="/app/assets/branding/novnc"

if [ -d "$BRANDING_DIR" ] && [ -d "$NOVNC_SRC" ]; then
    echo "🎨 Applying OpenClaw branding to noVNC..."

    # Copy noVNC to a writable location (container runs as non-root 'node' user)
    rm -rf "$NOVNC_DIR"
    cp -r "$NOVNC_SRC" "$NOVNC_DIR"

    # Copy branding assets (logos, favicons, CSS) into the writable copy
    cp -r "$BRANDING_DIR"/* "$NOVNC_DIR/" 2>/dev/null || true

    # Inject branding CSS into noVNC HTML files (vnc.html and vnc_lite.html)
    for HTML_FILE in "$NOVNC_DIR/vnc.html" "$NOVNC_DIR/vnc_lite.html"; do
        if [ -f "$HTML_FILE" ]; then
            # Only inject if not already branded
            if ! grep -q "branding.css" "$HTML_FILE"; then
                sed -i 's|</head>|<link rel="stylesheet" href="app/styles/branding.css">\n</head>|' "$HTML_FILE"
                echo "  ✅ Branded: $(basename $HTML_FILE)"
            fi
        fi
    done

    # Replace favicon if branding provides one
    if [ -f "$NOVNC_DIR/app/images/icons/novnc-favicon.png" ]; then
        for HTML_FILE in "$NOVNC_DIR/vnc.html" "$NOVNC_DIR/vnc_lite.html"; do
            if [ -f "$HTML_FILE" ]; then
                sed -i 's|favicon\.[a-z]*"|novnc-favicon.png"|g' "$HTML_FILE" 2>/dev/null || true
            fi
        done
    fi

    # Update page title
    for HTML_FILE in "$NOVNC_DIR/vnc.html" "$NOVNC_DIR/vnc_lite.html"; do
        if [ -f "$HTML_FILE" ]; then
            sed -i 's|<title>noVNC</title>|<title>OpenClaw Browser</title>|g' "$HTML_FILE" 2>/dev/null || true
        fi
    done

    echo "  🎨 noVNC branding applied successfully."
else
    echo "⚠️  Branding assets not found, using default noVNC theme."
    NOVNC_DIR="$NOVNC_SRC"
fi

# 6. Start noVNC (websockify)
# Check for websockify location (Debian usually /usr/bin/websockify)
if command -v websockify >/dev/null; then
    websockify --web "$NOVNC_DIR" $NOVNC_PORT localhost:$VNC_PORT > /tmp/novnc.log 2>&1 &
else
    echo "WARNING: websockify not found, noVNC will not be available."
fi

# 7. Start Chromium (listening on CDP)
# We use --remote-debugging-port to allow OpenClaw to connect
# Start Chromium in a loop to ensure it stays alive
# If you (or the AI) close it, it will respawn automatically.
(
  while true; do
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
      about:blank > /tmp/chromium.log 2>&1
    
    echo "Browser closed. Restarting in 2 seconds..."
    sleep 2
  done
) &

echo "Browser environment started."
echo "CDP endpoint: http://127.0.0.1:$CDP_PORT"

# 8. Configure OpenClaw to use this browser
CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"

mkdir -p "$CONFIG_DIR"

# Check for legacy config (moltbot.json) and migrate if openclaw.json is missing or new
LEGACY_CONFIG="$CONFIG_DIR/moltbot.json"
if [ -f "$LEGACY_CONFIG" ]; then
  # If openclaw.json doesn't exist, OR it's very small (likely just our auto-generated empty one)
  if [ ! -f "$CONFIG_FILE" ] || [ $(stat -c%s "$CONFIG_FILE" 2>/dev/null || echo 0) -lt 200 ]; then
    echo "Migrating legacy config $LEGACY_CONFIG to $CONFIG_FILE..."
    cp "$LEGACY_CONFIG" "$CONFIG_FILE"
  fi
fi

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

# 9. Pass control to the main application
# We set OPENCLAW_BROWSER_CDP_URL env var if not set, so the app uses this browser
export OPENCLAW_BROWSER_CDP_URL=${OPENCLAW_BROWSER_CDP_URL:-http://127.0.0.1:$CDP_PORT}
export OPENCLAW_BROWSER_EXECUTABLE_PATH=${OPENCLAW_BROWSER_EXECUTABLE_PATH:-/usr/bin/chromium}

# Ensure browser executable path is set in config (persisted via config file)
# This is robust against app updates because start-vnc.sh is preserved,
# and it updates the config file which is also preserved.
if [ -f "$CONFIG_FILE" ]; then
  node -e "
    const fs = require('fs');
    const path = require('path');
    const configFile = process.env.CONFIG_FILE;
    const exePath = process.env.OPENCLAW_BROWSER_EXECUTABLE_PATH;
    
    // Try to load json5 if available (in app dependencies), else fallback to JSON
    let JSON5 = JSON;
    try { JSON5 = require('json5'); } catch (e) {}

    try {
      if (fs.existsSync(configFile)) {
        const content = fs.readFileSync(configFile, 'utf8');
        // If file is empty, initialize empty object
        const config = content.trim() ? JSON5.parse(content) : {};
        
        // Ensure browser config object exists
        if (!config.browser) config.browser = {};
        
        // Only update if not already set correctly
        if (config.browser.executablePath !== exePath) {
          config.browser.executablePath = exePath;
          // Write back as standard JSON (indented)
          fs.writeFileSync(configFile, JSON.stringify(config, null, 2));
          console.log('Updated browser.executablePath to ' + exePath + ' in ' + configFile);
        }
      }
    } catch (err) {
      console.warn('Failed to update browser config in ' + configFile + ':', err.message);
    }
  "
fi

exec "$@"
