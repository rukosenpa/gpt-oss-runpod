# download.sh — model weights download
# Sourced by setup.sh, not run directly.
set -euo pipefail

echo ""
echo "── [3/4] Model ──"

if [ -f "$MODEL_DIR/config.json" ]; then
    echo "   Model already cached at $MODEL_DIR — skipping download."
    return 0
fi

echo "   Downloading openai/gpt-oss-120b (~65 GB)..."
echo ""
echo "   ⚠  Excluding /original (234 GB bf16) and /metal — these cause"
echo "      'Disk quota exceeded' errors even on 150 GB volumes."
echo ""

# Activate venv so huggingface-cli is available
source "$VENV_DIR/bin/activate"

hf download openai/gpt-oss-120b \
    --exclude "original/*" \
    --exclude "metal/*" \
    --local-dir "$MODEL_DIR" \

echo "   Download complete."
