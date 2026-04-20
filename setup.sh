# GPT-OSS 120B — RunPod setup & launch
#
# Paste usage (pod terminal):
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/gpt-oss-runpod/main/setup.sh | bash
#
# Docker startup command (RunPod template):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/gpt-oss-runpod/main/setup.sh)"
#
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/rukosenpa/gpt-oss-runpod/main"
SCRIPTS_DIR="/workspace/.gpt-oss-runpod"

echo "╔══════════════════════════════════════════════╗"
echo "║         GPT-OSS 120B  —  RunPod Setup        ║"
echo "╚══════════════════════════════════════════════╝"

# ── Pull sub-scripts to disk so they can be sourced (env vars survive) ──
mkdir -p "$SCRIPTS_DIR"

for script in env.sh packages.sh download.sh serve.sh; do
    curl -fsSL "$REPO_RAW/scripts/$script" -o "$SCRIPTS_DIR/$script"
    chmod +x "$SCRIPTS_DIR/$script"
done

# ── Source in order — each script sees vars set by the previous one ──
# shellcheck source=/dev/null
source "$SCRIPTS_DIR/env.sh"
source "$SCRIPTS_DIR/packages.sh"
source "$SCRIPTS_DIR/download.sh"

# serve.sh uses exec — replaces this process with vllm, so it must be last
source "$SCRIPTS_DIR/serve.sh"
