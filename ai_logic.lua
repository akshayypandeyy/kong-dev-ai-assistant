local http = require "resty.http"
local cjson = require "cjson.safe"
local kong = kong

-- Store last N requests in memory/cache
local request_history = {}

local function save_request_history(request_data, max_entries)
    table.insert(request_history, 1, request_data)
    while #request_history > max_entries do
        table.remove(request_history)
    end
end

local function call_openai(conf, prompt)
    local client = http.new()
    client:set_timeouts(3000, 10000, 30000)

    local payload = {
        model = conf.openai_model,
        messages = {
            { role = "system", content = [[
You are a Kong Developer Assistant AI.
Available tools: get_service_stats, get_routes, get_request_history, suggest_rate_limit
Respond in JSON: { "action_plan": "...", "tools_to_use": ["tool1","tool2"], "confidence": 0-100 }
]] },
            { role = "user", content = prompt }
        },
        max_tokens = conf.max_tokens
    }

    local res, err = client:request_uri(conf.openai_url, {
        method = "POST",
        body = cjson.encode(payload),
        headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. conf.openai_key
        },
        ssl_verify = conf.ssl_verify,
        keepalive_timeout = 60000
    })

    if not res or res.status ~= 200 then
        return { error = err or res.status }
    end

    local decoded = cjson.decode(res.body)
    local content = decoded.choices[1].message.content or "{}"
    local json_content = cjson.decode(content) or { action_plan = content, tools_to_use = {}, confidence = 0 }
    return json_content
end

-- Tools implemented in Lua
local tools = {
    get_service_stats = function()
        local res = kong.db.services:select()
        return { service_count = #res }
    end,
    get_routes = function()
        local res = kong.db.routes:select()
        return { route_count = #res }
    end,
    get_request_history = function()
        return { recent_requests = request_history }
    end,
    suggest_rate_limit = function()
        -- Simplified heuristic: block if >50 requests in last 10 requests
        local recent_count = #request_history
        if recent_count >= 10 then
            return { suggestion = "Enable rate-limiting on high-traffic endpoints" }
        else
            return { suggestion = "Traffic normal, no rate-limit needed" }
        end
    end
}

local function process_request(conf, user_input)
    ngx.req.read_body()
    local body = ngx.req.get_body_data() or "{}"
    local req_data = {
        path = ngx.var.request_uri,
        method = ngx.req.get_method(),
        headers = ngx.req.get_headers(),
        body = body
    }

    -- Save request history
    save_request_history(req_data, 20)  -- keep last 20 requests

    -- Build prompt for LLM agent
    local prompt = "User asked: " .. (user_input.question or "") ..
                   "\nRequest history length: " .. #request_history

    local ai_response = call_openai(conf, prompt)

    -- Execute tools suggested by AI
    local executed_tools = {}
    for _, t in ipairs(ai_response.tools_to_use or {}) do
        if tools[t] then
            executed_tools[t] = tools[t]()
        end
    end

    -- Return structured agentic response
    return {
        ai_summary = ai_response.action_plan,
        confidence = ai_response.confidence,
        tools_executed = executed_tools
    }
end

return { process_request = process_request }