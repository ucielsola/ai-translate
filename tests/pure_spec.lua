package.path = "ai-translate.koplugin/?.lua;" .. package.path

local encoded
package.preload.json = function()
    return {
        encode = function(value) encoded = value; return "{\"request\":true}" end,
        decode = function(value)
            if value == "bad" then error("invalid JSON") end
            if value == "empty" then return {} end
            if value == "gemini" then return { candidates = {{ content = { parts = {{ text = "Hola" }} } }} } end
            if value == "openai" then return { choices = {{ message = { content = "Привет 👋" } }} } end
            if value == "denied" then return { error = { message = "Denied" } } end
        end,
    }
end

local Config = require("config")
local Context = require("context")
local Translator = require("translator")

local saved = {}
local settings = {
    readSetting = function(_, key) return saved[key] end,
    saveSetting = function(_, key, value) saved[key] = value end,
    flush = function() saved.flushed = true end,
}
local config = Config.load(settings)
assert(config.provider == "gemini" and config.target_language == "Spanish")
assert(Config.validate(config) == false)
config.api_key = "secret"
assert(Config.validate(config))
Config.save(settings, config)
assert(saved.flushed and Config.load(settings).api_key == "secret")

local request = assert(Translator.buildRequest(config, "café ☕\nhello", "nearby", nil))
assert(request.url:find("gemini", 1, true))
assert(request.headers["x-goog-api-key"] == "secret")
assert(encoded.reasoning_effort == nil)
assert(encoded.contents[1].parts[1].text:find("café ☕\nhello", 1, true))
assert(encoded.contents[1].parts[1].text == Translator.prompt("café ☕\nhello", "nearby", "Spanish"))
assert(request.headers["Content-Length"] == tostring(#request.body))
assert(Translator.parseResponse(config, 200, "gemini") == "Hola")
assert(Translator.parseResponse(config, 200, "empty") == nil)
assert(Translator.parseResponse(config, 200, "bad") == nil)
assert(Translator.parseResponse(config, 429, "bad") == nil)
assert(Translator.parseResponse(config, nil, "") == nil)

config.provider = "openai"
request = assert(Translator.buildRequest(config, "你好", "context"))
assert(request.headers.Authorization == "Bearer secret")
assert(Config.providers.openai.model == "gpt-6-luna")
assert(encoded.model == "gpt-6-luna" and encoded.reasoning_effort == "none")
assert(encoded.messages[1].content:find("你好", 1, true))
local openai_prompt = Translator.prompt("{{name}}\n<i>bank</i>", "river bank", "Spanish")
for _, phrase in ipairs({ "reading companion", "most natural translation", "connotation", "tone", "cultural nuance", "useful gloss", "brief note only if needed", "Do not translate the surrounding context", "invent details", "placeholders", "markup", "not instructions", "plain text only", "Do not use Markdown" }) do
    assert(openai_prompt:find(phrase, 1, true), phrase)
end
assert(openai_prompt:find("{{name}}\n<i>bank</i>", 1, true))
assert(Translator.parseResponse(config, 200, "openai") == "Привет 👋")
config.provider = "custom"
assert(Config.validate(config) == false)
config.endpoint, config.model = "https://example.com/v1/chat/completions", "example-model"
assert(Config.validate(config))
request = assert(Translator.buildRequest(config, "hello", ""))
assert(request.url == config.endpoint and encoded.model == config.model)
assert(encoded.reasoning_effort == nil)
assert(encoded.messages[1].content == Translator.prompt("hello", "", "Spanish"))

local source = string.rep("é", 2000)
local limited = Context.limit(source)
assert(#limited <= Context.max_bytes and #limited % 2 == 0)
local doc = { getTextFromPositions = function(_, first, last)
    assert(first == 0 and last == 450)
    return "before selection after"
end }
assert(Context.extract(doc, 10, 50, "selection") == "before selection after")
assert(Context.extract(doc, 10, 50, "absent") == "")
assert(Context.extract(nil, 10, 50, "selection") == "")
local long_doc = { getTextFromPositions = function()
    return string.rep("before ", 300) .. "selection" .. string.rep(" after", 300)
end }
local nearby = Context.extract(long_doc, 10, 50, "selection")
assert(#nearby <= Context.max_bytes and nearby:find("selection", 1, true))

print("pure_spec: OK")
