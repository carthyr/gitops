# AI Coding Assistant Setup Guide

## Overview

Complete AI coding assistant platform running on Kubernetes with:
- **Qwen2.5-Coder 7B** (primary coding model)
- **LiteLLM** (OpenAI-compatible API gateway)
- **Ollama** (LLM inference with Intel GPU acceleration)
- **Continue.dev** (VS Code integration)

---

## Architecture

```
VS Code + Continue.dev (local)
          ↓
LiteLLM Gateway (k8s pod) → OpenAI-compatible API
          ↓
Ollama (k8s pod) + Intel Arc GPU
          ↓
Qwen2.5-Coder:7B model (4.7GB GGUF)
```

---

## Components

### 1. Ollama (LLM Inference)
- **Namespace**: `ollama`
- **GPU**: Intel Arc i915 (gpu.intel.com/i915: 1)
- **Storage**: 100Gi PVC (microk8s-hostpath)
- **Models Installed**:
  - `qwen2.5-coder:7b` (4.7GB) - Primary coding model
  - `qwen2.5-coder:1.5b-base` (986MB) - Lightweight model
  - `llama3.2:latest` (2.0GB) - General tasks
  - `llava:latest` (4.7GB) - Vision model

### 2. LiteLLM (AI Gateway)
- **Namespace**: `litellm`
- **Resources**: 100m CPU, 512Mi-1Gi RAM
- **API Endpoint**: `http://localhost:4000` (via port-forward) or `https://ai.technovise.local`
- **Model Aliases**:
  - `qwen-coder` → `ollama/qwen2.5-coder:7b`
  - `qwen2.5-coder-7b` → `ollama/qwen2.5-coder:7b`
  - `qwen-coder-1.5b` → `ollama/qwen2.5-coder:1.5b-base`
  - `llama3.2` → `ollama/llama3.2:latest`

### 3. Continue.dev (VS Code Extension)
- **Config**: `~/.continue/config.yaml`
- **Provider**: OpenAI-compatible (via LiteLLM)
- **Primary Model**: Qwen-Coder
- **Features**: Chat, autocomplete, code generation, refactoring

---

## Usage

### Starting LiteLLM Port-Forward

Since LiteLLM is not exposed externally (HTTPRoute requires DNS setup), use port-forwarding:

```bash
kubectl port-forward -n litellm svc/litellm 4000:4000
```

Keep this running in a terminal while using Continue.dev.

### Using Continue.dev in VS Code

1. **Install Continue.dev extension**:
   - Open VS Code
   - Go to Extensions (Cmd/Ctrl+Shift+X)
   - Search for "Continue"
   - Install "Continue - CodeLlama, GPT-4, etc."

2. **Configuration is already set up** at `~/.continue/config.yaml`

3. **Basic Commands**:
   - **Chat**: `Cmd/Ctrl+L` - Open chat sidebar
   - **Edit**: `Cmd/Ctrl+I` - Edit selected code
   - **Tab Autocomplete**: Start typing, press Tab to accept
   - **Explain**: Select code → Cmd/Ctrl+L → "Explain this code"

4. **Custom Commands** (configured):
   - `/test` - Generate unit tests for selected code
   - `/docstring` - Add documentation
   - `/optimize` - Optimize code for performance

### Example Prompts

**Code Generation**:
```
Create a Python function that reads a CSV file and converts it to a pandas DataFrame with error handling
```

**Code Explanation**:
```
Explain what this function does and how it handles edge cases
```

**Refactoring**:
```
Refactor this code to use async/await and improve error handling
```

**Testing**:
```
Write pytest tests for this function including edge cases
```

---

## API Testing

### List Available Models
```bash
curl http://localhost:4000/v1/models \
  -H "Authorization: Bearer sk-1234" | jq '.data[].id'
```

### Chat Completion
```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "qwen-coder",
    "messages": [{"role": "user", "content": "Write a Python hello world"}],
    "max_tokens": 100
  }' | jq -r '.choices[0].message.content'
```

### Streaming Response
```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-1234" \
  -d '{
    "model": "qwen-coder",
    "messages": [{"role": "user", "content": "Explain async/await in Python"}],
    "stream": true
  }'
```

---

## Model Management

### List Models in Ollama
```bash
kubectl exec -n ollama deployment/ollama -- ollama list
```

### Pull New Model
```bash
# Via kubectl exec
kubectl exec -n ollama deployment/ollama -- ollama pull <model-name>

# Examples
kubectl exec -n ollama deployment/ollama -- ollama pull deepseek-coder-v2:16b
kubectl exec -n ollama deployment/ollama -- ollama pull codellama:13b
```

### Remove Model
```bash
kubectl exec -n ollama deployment/ollama -- ollama rm <model-name>
```

### Test Model Directly (Ollama)
```bash
kubectl exec -it -n ollama deployment/ollama -- ollama run qwen2.5-coder:7b
```

---

## Monitoring

### Check Pod Status
```bash
# LiteLLM
kubectl get pods -n litellm
kubectl logs -n litellm deployment/litellm --tail=50 --follow

# Ollama
kubectl get pods -n ollama
kubectl logs -n ollama deployment/ollama --tail=50 --follow
```

### Check GPU Utilization
```bash
# Via Prometheus (if available)
# Query: DCGM_FI_DEV_GPU_UTIL{namespace="ollama"}

# Direct check in Ollama pod
kubectl exec -n ollama deployment/ollama -- intel_gpu_top
```

### Check Storage Usage
```bash
kubectl exec -n ollama deployment/ollama -- df -h /root/.ollama
```

---

## Troubleshooting

### Continue.dev Not Connecting

1. **Check port-forward is running**:
   ```bash
   lsof -i :4000
   ```
   If not running: `kubectl port-forward -n litellm svc/litellm 4000:4000`

2. **Test API manually**:
   ```bash
   curl http://localhost:4000/v1/models -H "Authorization: Bearer sk-1234"
   ```

3. **Check Continue.dev logs**:
   - VS Code → Help → Toggle Developer Tools → Console

### LiteLLM Pod Not Ready

```bash
# Check pod status
kubectl get pods -n litellm

# Check logs
kubectl logs -n litellm deployment/litellm --tail=100

# Common issues:
# - OOMKilled: Increase memory limits in manifests
# - CrashLoopBackOff: Check config.yaml syntax
```

### Ollama Model Not Loading

```bash
# Check if model exists
kubectl exec -n ollama deployment/ollama -- ollama list

# Check available disk space
kubectl exec -n ollama deployment/ollama -- df -h

# Restart Ollama
kubectl rollout restart deployment/ollama -n ollama
```

### Slow Inference

1. **Check GPU is being used**:
   ```bash
   kubectl logs -n ollama deployment/ollama | grep -i gpu
   ```

2. **Verify Intel GPU plugin**:
   ```bash
   kubectl get pods -n kube-system | grep intel-gpu-plugin
   ```

3. **Check resource limits**:
   ```bash
   kubectl describe pod -n ollama -l app=ollama | grep -A 5 Limits
   ```

---

## Performance Tuning

### Ollama Environment Variables

Edit `apps/ollama/ollama-app.yaml`:

```yaml
extraEnv:
  - name: OLLAMA_NUM_PARALLEL
    value: "1"  # Number of parallel requests (default: 1)
  - name: OLLAMA_MAX_LOADED_MODELS
    value: "1"  # Max models in memory (default: 1)
  - name: OLLAMA_CONTEXT_SIZE
    value: "4096"  # Context window size
```

### LiteLLM Timeout Settings

Edit `apps/litellm/manifests/litellm.yaml` ConfigMap:

```yaml
model_list:
  - model_name: qwen-coder
    litellm_params:
      timeout: 300  # Increase for slower responses
```

### Continue.dev Settings

Edit `~/.continue/config.yaml`:

```yaml
models:
  - name: Qwen-Coder
    completionOptions:
      temperature: 0.2  # Lower = more deterministic
      maxTokens: 2048   # Max response length
      topP: 0.9         # Nucleus sampling
```

---

## Advanced Configuration

### Adding More Models to LiteLLM

1. **Pull model in Ollama**:
   ```bash
   kubectl exec -n ollama deployment/ollama -- ollama pull deepseek-coder-v2:16b
   ```

2. **Edit LiteLLM ConfigMap** (`apps/litellm/manifests/litellm.yaml`):
   ```yaml
   - model_name: deepseek-coder
     litellm_params:
       model: ollama/deepseek-coder-v2:16b
       api_base: http://ollama.ollama.svc.cluster.local:11434
   ```

3. **Apply changes**:
   ```bash
   git add apps/litellm/manifests/litellm.yaml
   git commit -m "Add DeepSeek Coder model"
   git push
   ```
   ArgoCD will auto-sync.

### Multi-Model Comparison

LiteLLM supports fallbacks and routing:

```yaml
router_settings:
  routing_strategy: simple-shuffle  # or usage-based-routing
  allowed_fails: 3
  fallbacks: [
    {"qwen-coder": ["deepseek-coder"]},
  ]
```

---

## DNS Setup (Optional)

To use `https://ai.technovise.local` instead of port-forward:

1. **Update /etc/hosts**:
   ```bash
   sudo nano /etc/hosts
   # Add line:
   192.168.10.151  ai.technovise.local
   ```

2. **Update Continue.dev config** (`~/.continue/config.yaml`):
   ```yaml
   models:
     - name: Qwen-Coder
       apiBase: https://ai.technovise.local/v1
   ```

3. **Test**:
   ```bash
   curl https://ai.technovise.local/v1/models \
     -H "Authorization: Bearer sk-1234"
   ```

---

## Cleanup

### Remove Models
```bash
kubectl exec -n ollama deployment/ollama -- ollama rm qwen2.5-coder:1.5b-base
```

### Remove LiteLLM
```bash
kubectl delete -f apps/litellm/litellm-app.yaml
```

### Stop Port-Forward
```bash
# Find process
lsof -i :4000
# Kill it
kill <PID>
```

---

## Next Steps

1. **Explore Prompt Engineering**: Experiment with different prompts for better code generation
2. **Add More Models**: Try DeepSeek-Coder-V2:16B or CodeGemma for comparison
3. **Setup RAG**: Index your codebase for context-aware suggestions (future phase)
4. **Custom Fine-tuning**: Fine-tune models on your specific codebase (advanced)

---

## References

- [Continue.dev Documentation](https://continue.dev/docs)
- [LiteLLM Docs](https://docs.litellm.ai/)
- [Ollama Models Library](https://ollama.com/library)
- [Qwen2.5-Coder GitHub](https://github.com/QwenLM/Qwen2.5-Coder)
