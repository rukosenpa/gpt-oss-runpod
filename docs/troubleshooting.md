# Troubleshooting (April 2026)

Quick reference for every error you're likely to hit deploying GPT-OSS 120B on RunPod Blackwell.

---

## Package errors

### `No matching distribution found for torch==2.9.0.dev20250804+cu128`

**Cause**: You're using the old `vllm==0.10.1+gptoss` wheel, which hard-pins a PyTorch nightly that was purged from the index.

**Fix**: Use mainline vLLM instead. The `+gptoss` fork wheel is obsolete.

```bash
# Wrong — don't do this
uv pip install "vllm==0.10.1+gptoss" \
  --extra-index-url https://wheels.vllm.ai/gpt-oss/

# Correct
uv pip install "vllm==0.11.0"
```

---

### `ValueError: model type gpt_oss but Transformers does not recognize this architecture`

**Cause**: `transformers < 4.55.0` in the container image.

**Fix**:
```bash
pip install "transformers==4.57.6"
```

---

### `MXFP4 quantization requires triton >= 3.4.0 and kernels installed, defaulting to dequantize`

**Cause**: `triton`, `triton-kernels`, or `kernels` are missing. vLLM silently falls back to bf16 dequantization, which blows past 240 GB VRAM.

**Fix**:
```bash
pip install "triton==3.5.1" "triton-kernels==0.1.0" "kernels>=0.4.0"
```

---

## SM120 / Blackwell errors

### `Feature 'cvt.e2m1x2.f32' not supported on .target 'sm_120'`

**Cause**: FlashInfer JIT compiled without the `f` suffix, which enables FP4 instructions on Blackwell.

**Fix**: Set this before running anything:
```bash
export FLASHINFER_CUDA_ARCH_LIST=12.0f
```

> Single value only. `12.0f;12.1a` triggers `ValueError: too many values to unpack (expected 2)`.

---

### `ValueError: too many values to unpack (expected 2)` on FlashInfer import

**Cause**: `FLASHINFER_CUDA_ARCH_LIST` contains multiple values.

**Fix**: Use exactly `12.0f`, nothing else.

---

### `CUDA illegal memory access` mid-inference

**Cause**: CUDA graph capture bug on SM120.

**Fix**: Add `--enforce-eager` to the vllm serve command. You lose ~10% throughput but gain stability.

---

### `sm_120 is not compatible with the current PyTorch installation`

**Cause**: PyTorch < 2.8 doesn't include Blackwell kernels.

**Fix**:
```bash
pip install "torch==2.9.1+cu128" --index-url https://download.pytorch.org/whl/cu128
```

---

### flash-attn install fails / undefined symbols at runtime

**Cause**: FlashAttention 2 and 3 have no Blackwell sm_120 kernels. This is a known upstream limitation (Dao-AILab issues #1853, #1987). FA3 explicitly excludes sm_120.

**Fix**: Do not install `flash-attn` at all. Use `--attention-backend TRITON_ATTN` or `FLASHINFER`.

---

## Disk errors

### `Disk quota exceeded` during model download

**Cause**: vLLM or `huggingface-cli` pulled the `/original` folder (234 GB bf16 weights) or `/metal` folder in addition to the MXFP4 safetensors.

**Fix**: Always exclude them:
```bash
huggingface-cli download openai/gpt-oss-120b \
    --exclude "original/*" "metal/*" \
    --local-dir /workspace/models/gpt-oss-120b \
    --local-dir-use-symlinks False
```

---

## Output quality errors

### Model produces gibberish / incoherent responses

**Cause**: `transformers==5.0.0rc1` has a regression that breaks gpt-oss output (sglang issue #15082).

**Fix**:
```bash
pip install "transformers==4.57.6"
```

---

## RunPod / network errors

### `502 Bad Gateway` on proxy URL immediately after start

**Cause**: Normal — the model takes 3–10 minutes to load into VRAM after the container starts. The proxy returns 502 until vLLM's Uvicorn is ready.

**Fix**: Wait. Poll `/health` until it returns 200:
```bash
until curl -sf https://<POD_ID>-8000.proxy.runpod.net/health; do
    echo "waiting..."; sleep 10
done
```

---

### Requests hang or return empty after ~100 seconds

**Cause**: RunPod's HTTP proxy has a 100-second hard timeout.

**Fix**: Use streaming (`"stream": true`) for long generations, or remap port 8000 to TCP:
RunPod Console → Edit Pod → change port 8000 type from HTTP to TCP → reconnect using the TCP address shown in the Connect panel.

---

### `401 Unauthorized` from HuggingFace during download

**Cause**: Missing or invalid `HF_TOKEN`. GPT-OSS 120B itself is not gated but anonymous requests get rate-limited aggressively on large downloads.

**Fix**: Set `HF_TOKEN` as a RunPod pod environment variable or Secret.
