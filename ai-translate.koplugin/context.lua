local Context = {}
Context.max_bytes = 1600
Context.radius = 400
Context.following_chars = 150

local function trim_utf8(text, limit)
    if #text <= limit then return text end
    local cut = limit
    while cut > 0 and text:byte(cut + 1) and text:byte(cut + 1) >= 128 and text:byte(cut + 1) < 192 do
        cut = cut - 1
    end
    return text:sub(1, cut)
end

function Context.limit(text)
    if type(text) ~= "string" then return "" end
    return trim_utf8(text, Context.max_bytes)
end

local function around_selection(text, selected)
    if type(text) ~= "string" or type(selected) ~= "string" then return "" end
    local at = text:find(selected, 1, true)
    if not at or #selected > Context.max_bytes then return "" end
    if #text <= Context.max_bytes then return text end
    local space = Context.max_bytes - #selected
    local first = math.max(1, at - math.floor(space / 2))
    first = math.min(first, #text - Context.max_bytes + 1)
    while first <= #text and text:byte(first) >= 128 and text:byte(first) < 192 do
        first = first + 1
    end
    return trim_utf8(text:sub(first, first + Context.max_bytes - 1), Context.max_bytes)
end

function Context.extract(document, pos0, pos1, selected)
    if not document or not pos0 or not pos1 then return "" end
    local text
    if type(pos0) == "number" and type(pos1) == "number" and document.getTextFromPositions then
        local first = math.max(0, pos0 - Context.radius)
        local last = pos1 + Context.radius
        local ok, result = pcall(document.getTextFromPositions, document, first, last)
        if ok then text = result end
    elseif type(pos0) == "string" and type(pos1) == "string" and document.getTextFromXPointers then
        local first, last = pos0, pos1
        if document.getPrevVisibleWordStart then
            for _ = 1, 45 do
                local ok, previous = pcall(document.getPrevVisibleWordStart, document, first)
                if not ok or not previous or previous == first then break end
                first = previous
            end
        end
        if document.getNextVisibleChar then
            for _ = 1, Context.following_chars do
                local ok, next_pos = pcall(document.getNextVisibleChar, document, last)
                if not ok or not next_pos or next_pos == last then break end
                last = next_pos
            end
        end
        local ok, result = pcall(document.getTextFromXPointers, document, first, last)
        if ok then text = result end
    elseif type(pos0) == "table" and type(pos0.page) == "number" and document.getPageText then
        local ok, page = pcall(document.getPageText, document, pos0.page)
        if ok and type(page) == "string" and type(selected) == "string" then
            local at = page:find(selected, 1, true)
            if at then
                local first = math.max(1, at - Context.radius)
                local last = math.min(#page, at + #selected + Context.radius)
                text = page:sub(first, last)
            end
        end
    end
    if type(text) ~= "string" then return "" end
    return around_selection(text, selected)
end

return Context
