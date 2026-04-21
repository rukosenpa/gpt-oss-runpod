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
echo ""

source "$VENV_DIR/bin/activate"

exec vllm serve "$MODEL_DIR" \
    --served-model-name gpt-oss-120b \
    --tokenizer openai/gpt-oss-120b \
    --host 0.0.0.0 \
    --port 8000 \
    --gpu-memory-utilization 0.90 \
    --max-model-len 127300 \
    --download-dir /workspace/hf-cache \
    --enforce-eager \
    --trust-remote-code
