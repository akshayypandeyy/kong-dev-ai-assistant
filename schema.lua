local typedefs = require "kong.db.schema.typedefs"

return {
  name = "dev-ai-assistant",
  fields = {
    { protocols = typedefs.protocols_http },
    {
      config = {
        type = "record",
        fields = {
          { openai_url = { type = "string", required = true } },
          { openai_model = { type = "string", required = false, default = "gpt-4o-mini" } },
          { openai_key = { type = "string", required = true, encrypted = true, referenceable = true } },
          { max_tokens = { type = "number", default = 500 } },
          { ssl_verify = { type = "boolean", default = false } },
          { included_tools = {
              type = "array",
              elements = { type = "string", one_of = { "get_service_stats", "get_routes", "suggest_config" } },
              default = { "get_service_stats", "get_routes" }
          }},
        }
      }
    }
  }
}