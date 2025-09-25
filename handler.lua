local ai_logic = require "kong.plugins.dev-ai-assistant.ai_logic"
local cjson = require "cjson.safe"

local DevAIAssistant = {
  VERSION = "1.1",
  PRIORITY = 900,
}

-- Only handle requests to /ai-assist
function DevAIAssistant:access(conf)
  local uri = ngx.var.request_uri or ""
  if not uri:find("/ai-assist") then
    return
  end

  ngx.req.read_body()
  local body = ngx.req.get_body_data() or "{}"
  local user_input = cjson.decode(body) or {}

  -- Call the Lua-only agentic AI logic
  local response = ai_logic.process_request(conf, user_input)

  -- Add optional metadata for demo
  local demo_metadata = {
    timestamp = ngx.time(),
    request_path = ngx.var.request_uri,
    request_method = ngx.req.get_method()
  }

  -- Return structured JSON response
  return kong.response.exit(200, cjson.encode({
    agent_summary = response.ai_summary,
    confidence = response.confidence,
    tools_executed = response.tools_executed,
    demo_metadata = demo_metadata
  }))
end

return DevAIAssistant