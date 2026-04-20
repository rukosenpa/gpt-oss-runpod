# env.sh — environment variables and guards
# Sourced by setup.sh, not run directly.
set -euo pipefail

echo ""
echo "── [1/4] Environment ──"

# ── HF_TOKEN guard ──
if [ -z "${HF_TOKEN:-}" ]; then
    echo ""
    echo "ERROR: HF_TOKEN is not set."
    echo ""
    echo "Fix options:"
    echo "  1. RunPod UI → Edit Template → Environment Variables → add HF_TOKEN"
    echo "  2. RunPod UI → Settings → Secrets → add HF_TOKEN (encrypted)"
    echo "  3. Prepend inline: HF_TOKEN=hf_xxx bash -c \"\$(curl ...)\""
    echo ""
    exit 1
fi

# Both env var names used by different HF tools
export HF_TOKEN="$HF_TOKEN"
export HUGGING_FACE_HUB_TOKEN="$HF_TOKEN"

# Paths — all under /workspace so they survive pod restarts
export HF_HOME="/workspace/hf-cache"
export TMPDIR="/workspace/tmp"
export VENV_DIR="/workspace/.venv"
export MODEL_DIR="/workspace/models/gpt-oss-120b"

# Fast HF downloads
export HF_HUB_ENABLE_HF_TRANSFER=1

# ── SM120 / Blackwell-specific ──
# CRITICAL: single value with 'f' suffix
# Multi-arch strings like "12.0f;12.1a" break FlashInfer with "too many values to unpack"
export FLASHINFER_CUDA_ARCH_LIST=12.0f

# Spawn avoids CUDA fork issues in vLLM multiprocessing
export VLLM_WORKER_MULTIPROC_METHOD=spawn

# Prevents OOM from memory fragmentation under long sessions
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

mkdir -p /workspace/hf-cache /workspace/tmp /workspace/models

echo "   HF_HOME   : $HF_HOME"
echo "   MODEL_DIR : $MODEL_DIR"
echo "   VENV_DIR  : $VENV_DIR"
echo "   GPU       : $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo 'unknown')"
echo "   Done."
