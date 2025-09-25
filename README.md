# Dev AI Assistant

**A Lua-only, agentic AI plugin for Kong Gateway**

Transform your Kong API Gateway into a **Developer AI Assistant** that answers queries about your APIs, services, traffic, and configurations using a large language model (LLM), all from within Kong.

---

## Features

- **Agentic Behavior**: AI decides which Lua tools to execute based on your query.
- **Lua-only Implementation**: No Python or external backend required.
- **Traffic Analysis**: Summarizes API requests, detects anomalies, and highlights trends.
- **Configuration Guidance**: Suggests rate limits, plugins, and security improvements.
- **Structured JSON Responses**: Returns `agent_summary`, `tools_executed`, and `confidence`.
- **Secure Access**: Optional Bearer token to protect `/ai-assist`.
- **Customizable Tools**: Configure which tools the agent can access.

---

## Getting Started

### 1. Create a Kong Service and Route

```bash
# Create a service
curl -X POST http://localhost:8001/services \
-d "name=ai-service" \
-d "url=http://mock-upstream"

# Create a route for /ai-assist
curl -X POST http://localhost:8001/services/ai-service/routes \
-d "paths[]=/ai-assist" \
-d "methods[]=POST"

### 2. Attach the Plugin

curl -X POST http://localhost:8001/routes/<route-id>/plugins \
-d "name=dev-ai-assistant" \
-d "config.openai_url=https://api.openai.com/v1/chat/completions" \
-d "config.openai_key=sk-XXXXXXXXXXXXXXXXX" \
-d "config.openai_model=gpt-4o-mini" \
-d "config.bearer_token=my-secret-token"


### 3. Send a POST request to /ai-assist

curl -X POST http://localhost:8000/ai-assist \
-H "Content-Type: application/json" \
-H "Authorization: Bearer my-secret-token" \
-d '{
"question": "Suggest rate limits for high-traffic endpoints"
}'

Sample Response:
{
"agent_summary": "Enable rate-limiting on /orders and /payments endpoints...",
"confidence": 92,
"tools_executed": {
"get_request_history": {
"recent_requests": [...]
},
"suggest_rate_limit": {
"suggestion": "Enable rate-limiting on high-traffic endpoints"
}
},
"demo_metadata": {
"timestamp": 1700000000,
"request_path": "/ai-assist",
"request_method": "POST"
}
}


Supported Tools
get_service_stats – Count services in Kong.

get_routes – List all routes.

get_request_history – Show last 20 requests.

suggest_rate_limit – Suggest rate-limiting based on traffic.
