local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local ButtonDialog = require("ui/widget/buttondialog")
local InputDialog = require("ui/widget/inputdialog")
local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local _ = require("gettext")

local prefix = ((...) or ""):match("(.-)[^%.]+$") or ""
local Config = require(prefix .. "config")
local Context = require(prefix .. "context")
local Translator = require(prefix .. "translator")
local Transport = require(prefix .. "transport")
local View = require(prefix .. "ui")
local version = require(prefix .. "_meta").version

local Plugin = WidgetContainer:extend{
    name = "ai-translate",
    is_doc_only = true,
}

local function prompt(title, value, save)
    local dialog
    dialog = InputDialog:new{
        title = title,
        input = value or "",
        buttons = {{
            { text = _("Cancel"), callback = function() UIManager:close(dialog) end },
            { text = _("Save"), callback = function()
                local input = dialog:getInputText()
                UIManager:close(dialog)
                save(input)
            end },
        }},
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function Plugin:init()
    self.settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/ai-translate.lua")
    self.config = Config.load(self.settings)
    self.ui.menu:registerToMainMenu(self)
    if self.ui.highlight and self.ui.highlight.addToHighlightDialog then
        self.ui.highlight:addToHighlightDialog("ai_translate", function(highlight)
            return {
                text = _("Translate"),
                callback = function()
                    local selection = highlight.selected_text or {}
                    local text, pos0, pos1 = selection.text, selection.pos0, selection.pos1
                    if highlight.onClose then pcall(highlight.onClose, highlight) end
                    if highlight.highlight_dialog then UIManager:close(highlight.highlight_dialog) end
                    self:translate(text, pos0, pos1)
                end,
            }
        end)
    end
    if self.ui.dictionary and self.ui.dictionary.addToDictButtons then
        self.ui.dictionary:addToDictButtons{
            id = "ai_translate",
            menu_text = _("Translate"),
            text = _("Translate"),
            callback = function(popup) self:translateFromDictionary(popup) end,
        }
    end
end

function Plugin:translateFromDictionary(popup)
    local text = popup and (popup.selection_text or popup.word or popup.text)
    if type(text) == "table" then text = text.text or text.word end
    local pos0, pos1 = popup and popup.pos0, popup and popup.pos1
    if popup then UIManager:close(popup) end
    self:translate(text, pos0, pos1)
end

function Plugin:onDictButtonsReady(popup, rows)
    if self.ui.dictionary and self.ui.dictionary.addToDictButtons then return end
    table.insert(rows, { { text = _("Translate"), callback = function()
        self:translateFromDictionary(popup)
    end } })
end

function Plugin:translate(text, pos0, pos1)
    if type(text) ~= "string" or text:match("^%s*$") then
        View.message(_("AI Translate"), _("Select text to translate."))
        return
    end
    local valid, reason = Config.validate(self.config)
    if not valid then
        View.message(_("AI Translate"), reason or _("Set a provider and API key in AI Translate settings."))
        return
    end
    local context = Context.extract(self.ui.document, pos0, pos1, text)
    local request, build_error = Translator.buildRequest(self.config, text, context)
    if not request then
        View.message(_("AI Translate"), build_error or _("Could not prepare translation."))
        return
    end
    self:cancelRequest()
    local token = {}
    self.request_token = token
    self.progress = View.progress(function() self:cancelRequest() end)
    local handle, start_error = Transport.start(request, function(status, body, err)
        if self.request_token ~= token then return end
        self.request_token = nil
        self.request_handle = nil
        View.close(self.progress)
        self.progress = nil
        if err then
            View.message(_("Translation error"), tostring(err))
            return
        end
        local translated, parse_error = Translator.parseResponse(self.config, status, body)
        View.message(translated and _("Translation") or _("Translation error"), translated or parse_error or _("Empty response."))
    end)
    self.request_handle = handle
    if not handle then
        self.request_token = nil
        View.close(self.progress)
        self.progress = nil
        View.message(_("Translation error"), start_error or _("Could not start request."))
    end
end

function Plugin:cancelRequest()
    self.request_token = nil
    if self.request_handle then self.request_handle:cancel() end
    self.request_handle = nil
    View.close(self.progress)
    self.progress = nil
end

function Plugin:saveConfig()
    Config.save(self.settings, self.config)
end

function Plugin:showSettings()
    local dialog
    local function close() UIManager:close(dialog) end
    local buttons = {
            { { text = _("Provider: ") .. (self.config.provider or ""), callback = function()
                close()
                local choice
                choice = ButtonDialog:new{
                    title = _("Provider"),
                    buttons = {
                        { { text = "Gemini", callback = function() self.config.provider = "gemini"; self:saveConfig(); UIManager:close(choice) end } },
                        { { text = "OpenAI-compatible", callback = function() self.config.provider = "openai"; self:saveConfig(); UIManager:close(choice) end } },
                        { { text = _("Custom"), callback = function() self.config.provider = "custom"; self:saveConfig(); UIManager:close(choice) end } },
                    },
                }
                UIManager:show(choice)
            end } },
            { { text = _("Target language: ") .. (self.config.target_language or ""), callback = function()
                close()
                prompt(_("Target language"), self.config.target_language, function(value)
                    self.config.target_language = value
                    self:saveConfig()
                end)
            end } },
            { { text = _("API key"), callback = function()
                close()
                prompt(_("API key"), "", function(value)
                    if value ~= "" then self.config.api_key = value; self:saveConfig() end
                end)
            end } },
    }
    if self.config.provider == "custom" then
        buttons[#buttons + 1] = { { text = _("Custom endpoint"), callback = function()
                close()
                prompt(_("Custom endpoint"), self.config.endpoint, function(value)
                    self.config.endpoint = value; self:saveConfig()
                end)
            end } }
        buttons[#buttons + 1] = { { text = _("Custom model"), callback = function()
                close()
                prompt(_("Custom model"), self.config.model, function(value)
                    self.config.model = value; self:saveConfig()
                end)
            end } }
    end
    buttons[#buttons + 1] = { { text = _("Version: ") .. version, enabled = false } }
    buttons[#buttons + 1] = { { text = _("Close"), callback = close } }
    dialog = ButtonDialog:new{
        title = _("AI Translate"),
        buttons = buttons,
    }
    UIManager:show(dialog)
end

function Plugin:addToMainMenu(items)
    items.ai_translate = {
        text = _("AI Translate"), sorting_hint = "tools",
        callback = function() self:showSettings() end,
    }
end

function Plugin:onCloseDocument()
    self:cancelRequest()
end

return Plugin
