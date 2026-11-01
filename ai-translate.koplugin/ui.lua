local UIManager = require("ui/uimanager")
local ButtonDialog = require("ui/widget/buttondialog")
local TextViewer = require("ui/widget/textviewer")
local _ = require("gettext")

local UI = {}

function UI.progress(cancel)
    local dialog
    dialog = ButtonDialog:new{
        title = _("AI Translate"),
        buttons = {
            { { text = _("Translating…"), enabled = false } },
            { { text = _("Cancel"), callback = function()
                cancel()
            end } },
        },
    }
    UIManager:show(dialog)
    return dialog
end

function UI.close(dialog)
    if dialog then UIManager:close(dialog) end
end

function UI.message(title, message)
    local viewer = TextViewer:new{
        title = title,
        text = message,
        scroll = true,
    }
    UIManager:show(viewer)
end

return UI
