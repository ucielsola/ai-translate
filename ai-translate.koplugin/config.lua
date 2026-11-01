local Config = {}

Config.defaults = {
    provider = "gemini",
    target_language = "Spanish",
    timeout = 30,
}

Config.providers = {
    gemini = { endpoint = "https://generativelanguage.googleapis.com/v1beta/models/", model = "gemini-2.5-flash" },
    openai = { endpoint = "https://api.openai.com/v1/chat/completions", model = "gpt-6-luna" },
}

function Config.load(settings)
    local config = {}
    for key, value in pairs(Config.defaults) do config[key] = value end
    for _, key in ipairs({ "provider", "target_language", "api_key", "endpoint", "model" }) do
        local value = settings:readSetting(key)
        if value ~= nil then config[key] = value end
    end
    return config
end

function Config.save(settings, config)
    for _, key in ipairs({ "provider", "target_language", "api_key", "endpoint", "model" }) do
        settings:saveSetting(key, config[key])
    end
    settings:flush()
end

function Config.validate(config)
    if not Config.providers[config.provider] and config.provider ~= "custom" then
        return false, "Unsupported provider"
    end
    if type(config.target_language) ~= "string" or config.target_language:match("^%s*$") then
        return false, "Choose a target language"
    end
    if type(config.api_key) ~= "string" or config.api_key:match("^%s*$") then
        return false, "Enter an API key"
    end
    if config.provider == "custom" then
        if type(config.endpoint) ~= "string" or not config.endpoint:match("^https://[^%s]+$") then
            return false, "Enter an HTTPS endpoint"
        end
        if type(config.model) ~= "string" or config.model:match("^%s*$") then
            return false, "Enter a model"
        end
    end
    return true
end

return Config
