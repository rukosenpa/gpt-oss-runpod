#!/bin/bash
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

# ── Check if vLLM is already installed at the right version ──
if python -c "import vllm; assert vllm.__version__ == '0.11.0'" 2>/dev/null; then
    echo "   vLLM 0.11.0 already installed — skipping."
    return 0
fi

echo "   Installing packages (first run: ~10 min on fast network)..."

# PyTorch cu128 — install before vLLM so vLLM doesn't pull its own
# torch==2.9.1+cu128 supports Blackwell sm_120
uv pip install \
    "torch==2.9.1+cu128" \
    --index-url https://download.pytorch.org/whl/cu128

# vLLM mainline — has native gpt_oss support since v0.10.1
# !! DO NOT use vllm==0.10.1+gptoss !!
#    Its pinned torch nightly (2.9.0.dev20250804+cu128) was purged from the PyTorch index.
#    See: huggingface.co/openai/gpt-oss-20b/discussions/165
uv pip install "vllm==0.11.0"

# Transformers — minimum 4.55.0 for gpt_oss architecture recognition
# !! DO NOT use transformers==5.0.0rc1 !!
#    Causes gibberish output specifically on gpt-oss. See: sglang issue #15082
uv pip install \
    "transformers==4.57.6" \
    "tokenizers==0.22.1" \
    "accelerate==1.10.1"

# MXFP4 kernel deps — required for mxfp4 quantization to actually use GPU kernels
# Without these, vLLM logs a warning and dequantizes (slow, defeats the point)
uv pip install \
    "triton==3.5.1" \
    "triton-kernels==0.1.0" \
    "kernels>=0.4.0"

# FlashInfer — attention backend for SM120
# !! DO NOT install flash-attn (FA2 or FA3) !!
#    Neither has Blackwell sm_120 kernels. FA3 explicitly excludes sm_120.
#    See: Dao-AILab/flash-attention issues #1853, #1987
uv pip install "flashinfer==0.6.3"

# HuggingFace tooling
uv pip install \
    "huggingface_hub>=1.2.0" \
    "hf_transfer>=0.1.9" \
    "safetensors>=0.6.1" \
    "tiktoken>=0.12.0"

echo "   Packages installed."
