# packages.sh — Python environment and package installation
# Sourced by setup.sh, not run directly.
set -euo pipefail

echo ""
echo "── [2/4] Packages ──"

# ── Create venv if it doesn't exist ──
if [ ! -d "$VENV_DIR" ]; then
    echo "   Creating virtualenv at $VENV_DIR (Python 3.12)..."
    pip install -q uv
    uv venv --python 3.12 --seed "$VENV_DIR"
else
    echo "   Virtualenv already exists at $VENV_DIR."
fi

source "$VENV_DIR/bin/activate"


echo "   Installing packages (first run: ~10 min on fast network)..."

uv pip install --pre vllm --extra-index-url https://wheels.vllm.ai/gpt-oss/ --index-strategy unsafe-best-match

echo "   Packages installed."
