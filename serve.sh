#!/bin/bash
# serve.sh — vLLM server launch
# Sourced by setup.sh, not run directly.
# Uses exec — replaces the current process. Must be sourced last.
set -euo pipefail

echo ""
echo "── [4/4] Serve ──"
echo ""
echo "   Model  : $MODEL_DIR"
echo "   Port   : 8000"
echo "   GPU    : $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || echo 'unknown')"
echo "   Flags  : MARLIN MXFP4 · TRITON_ATTN · enforce-eager (required on SM120)"
echo ""

source "$VENV_DIR/bin/activate"

# Flag rationale:
#   --quantization mxfp4          native MXFP4 weights (~63 GB, fits in 96 GB VRAM)
#   --mxfp4-backend MARLIN        safe path for SM120; use CUTLASS for +30% throughput
#                                 but requires custom image (eugr/spark-vllm-docker)
#   --attention-backend TRITON_ATTN  FA2/FA3 unsupported on Blackwell sm_120
#   --enforce-eager               CUDA-graph capture causes illegal memory access on SM120
#   --kv-cache-dtype fp8 NOT set  safe on newer vLLM but conservative default kept here
exec vllm serve "$MODEL_DIR" \
    --served-model-name gpt-oss-120b \
    --tokenizer openai/gpt-oss-120b \
    --host 0.0.0.0 \
    --port 8000 \
    --quantization mxfp4 \
    --mxfp4-backend MARLIN \
    --attention-backend TRITON_ATTN \
    --gpu-memory-utilization 0.90 \
    --max-model-len 32768 \
    --max-num-seqs 16 \
    --max-num-batched-tokens 4096 \
    --download-dir /workspace/hf-cache \
    --enforce-eager \
    --trust-remote-code
