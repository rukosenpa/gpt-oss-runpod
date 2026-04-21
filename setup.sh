set -euo pipefail
 
echo "╔══════════════════════════════════════════════╗"
echo "║         GPT-OSS 120B  —  RunPod Setup        ║"
echo "╚══════════════════════════════════════════════╝"
 
# ── Wait for network ──────────────────────────────────────────────────────────
# The Docker Command executes before the container network stack is fully up,
# causing spurious DNS failures ("could not resolve host") on first boot.
# Waiting here is harmless in SSH sessions (network is already ready).
echo "Checking network..."
for i in $(seq 1 10); do
    if curl -fsSL --max-time 3 https://huggingface.co > /dev/null 2>&1; then
        echo "Network ready."
        break
    fi
    echo "  attempt $i/10, retrying in 3s..."
    sleep 3
    if [ "$i" -eq 10 ]; then
        echo "ERROR: network not available after 30s. Exiting."
        exit 1
    fi
done
 
SCRIPTS_DIR="/opt/gpt-oss/scripts"
 
source "$SCRIPTS_DIR/env.sh"
source "$SCRIPTS_DIR/packages.sh"
source "$SCRIPTS_DIR/download.sh"
 
# serve.sh uses exec — must be sourced last
source "$SCRIPTS_DIR/serve.sh"