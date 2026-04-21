# gpt-oss-runpod

One-command deployment of [GPT-OSS 120B](https://huggingface.co/openai/gpt-oss-120b) on a RunPod pod with an NVIDIA RTX PRO 6000 Blackwell (96 GB) or any other 96 GB VRAM GPU.

Tested and documented as of **April 2026**. See [docs/troubleshooting.md](docs/troubleshooting.md) for known breakage and fixes.

---

## Quick start

### Option A — Paste in pod terminal

SSH into your pod and run:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/gpt-oss-runpod/main/setup.sh | bash
```

Or if `HF_TOKEN` isn't set as a pod env var yet:

```bash
HF_TOKEN=hf_xxx bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/gpt-oss-runpod/main/setup.sh)"
```

### Option B — Docker startup command (RunPod template)

In **Edit Template → Docker Command**, paste:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/gpt-oss-runpod/main/setup.sh)"
```

`runpod/pytorch` uses `/bin/bash` as its entrypoint, so this works directly — no wrapper image needed.

---

## RunPod pod configuration

| Setting | Value |
|---|---|
| GPU | 1 × RTX PRO 6000 Blackwell (96 GB) |
| Container Image | `runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404` |
| Container Disk | 40 GB |
| Volume Disk | **100 GB** at `/workspace` |
| HTTP Port | `8000` |
| Environment Variable | `HF_TOKEN = hf_xxx` |


Other env vars:
HF_TOKEN="{{ RUNPOD_SECRET_HF_TOKEN }}"
HUGGING_FACE_HUB_TOKEN="{{ RUNPOD_SECRET_HF_TOKEN }}"
HF_HOME=/workspace/hf-cache
HF_HUB_ENABLE_HF_TRANSFER=1
TMPDIR=/workspace/tmp
Maybe not all of them are needed

> **Volume is required.** Model weights (~65 GB) and the Python venv are stored on `/workspace` so they survive pod restarts. Without it you re-download 65 GB every time.

---

## What `setup.sh` does

| Step | Script | Runs again? |
|---|---|---|
| Set env vars + guards | `scripts/env.sh` | Always (sourced) |
| Create venv + install packages | `scripts/packages.sh` | Skipped if vLLM 0.11.0 already installed |
| Download model weights | `scripts/download.sh` | Skipped if `config.json` exists |
| Launch vLLM server | `scripts/serve.sh` | Always |

First run takes ~25 min (mostly download). Subsequent starts take ~2 min.

---

## Pinned versions (April 2026)

| Package | Version | Why pinned |
|---|---|---|
| `vllm` | `0.11.0` | Mainline with native `gpt_oss` support. Don't use `0.10.1+gptoss` — its torch nightly was removed from the index. |
| `transformers` | `4.57.6` | Minimum for `gpt_oss` architecture. Don't use `5.0.0rc1` — causes gibberish output. |
| `torch` | `2.9.1+cu128` | Blackwell sm_120 support. |
| `triton` | `3.5.1` | Required for MXFP4 kernels. |
| `flashinfer` | `0.6.3` | SM120 attention backend. Don't install `flash-attn` — FA2/FA3 have no Blackwell kernels. |
| NVIDIA driver | `580.x` | Open kernel modules, required on Blackwell. |

---

## API usage

Once serving, the endpoint is OpenAI-compatible.

```bash
# Health check
curl http://localhost:8000/health

# Chat completion
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-oss-120b",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 256
  }'
```

Over RunPod's proxy: `https://<POD_ID>-8000.proxy.runpod.net/v1/...`

> **Proxy timeout**: RunPod's HTTP proxy has a 100-second hard timeout. For long generations use `"stream": true` or remap port 8000 to TCP in the pod settings.

---

## Repo structure

```
gpt-oss-runpod/
├── setup.sh              # entrypoint — curl this
├── scripts/
│   ├── env.sh            # environment variables and guards
│   ├── packages.sh       # venv creation and pip installs
│   ├── download.sh       # model download with exclusions
│   └── serve.sh          # vllm serve launch
└── docs/
    └── troubleshooting.md
```

---

## License

MIT