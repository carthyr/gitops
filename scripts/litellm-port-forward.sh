#!/bin/bash
# Port-forward LiteLLM for local development
# Usage: ./scripts/litellm-port-forward.sh

echo "🚀 Starting port-forward to LiteLLM..."
echo "📍 LiteLLM API will be available at: http://localhost:4000"
echo "🔑 API Key: sk-1234"
echo ""
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward -n litellm svc/litellm 4000:4000
