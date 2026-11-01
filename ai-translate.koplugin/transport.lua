local UIManager = require("ui/uimanager")
local ffi = require("ffi")

pcall(ffi.cdef, [[
    int fork(void);
    int kill(int pid, int sig);
    int waitpid(int pid, int *status, int options);
    void _exit(int status);
]])

local Transport = {}
local WNOHANG = 1
local SIGKILL = 9

local function reap(pid)
    return tonumber(ffi.C.waitpid(pid, nil, WNOHANG)) ~= 0
end

local function request_in_child(request, result_file)
    local ok, status, body, err = pcall(function()
        local http = require("socket.http")
        require("ssl.https")
        local ltn12 = require("ltn12")
        local socketutil = require("socketutil")
        local timeout = math.max(1, math.min(tonumber(request.timeout) or 30, 120))
        socketutil:set_timeout(timeout, timeout)
        local chunks = {}
        local _, code, headers, request_err = http.request({
            url = request.url,
            method = "POST",
            headers = request.headers,
            source = ltn12.source.string(request.body),
            sink = ltn12.sink.table(chunks),
        })
        local response = table.concat(chunks)
        local length = headers and tonumber(headers["content-length"])
        if length and #response < length then
            return nil, nil, "Incomplete response"
        end
        if not tonumber(code) then
            return nil, nil, tostring(code or request_err or "Network error")
        end
        return tonumber(code), response, nil
    end)
    if not ok then
        err, status, body = tostring(status), nil, nil
    end
    local tmp = result_file .. ".writing"
    local file = io.open(tmp, "wb")
    if file then
        file:write(tostring(status or "") .. "\n" .. tostring(err or "") .. "\n" .. (body or ""))
        file:close()
        os.rename(tmp, result_file)
    end
    ffi.C._exit(0)
end

function Transport.start(request, callback)
    local result_file = os.tmpname()
    os.remove(result_file)
    local pid = tonumber(ffi.C.fork())
    if pid == 0 then
        request_in_child(request, result_file)
    end
    if not pid or pid < 0 then
        return nil, "Could not start network request"
    end

    local handle = { pid = pid, cancelled = false, finished = false }
    local deadline = os.time() + math.max(1, math.min(tonumber(request.timeout) or 30, 120)) + 5
    local function finish(status, body, err)
        if handle.finished then return end
        handle.finished = true
        os.remove(result_file)
        if not reap(pid) then
            ffi.C.kill(pid, SIGKILL)
            ffi.C.waitpid(pid, nil, 0)
        end
        if not handle.cancelled then callback(status, body, err) end
    end
    function handle:cancel()
        if self.finished then return end
        self.cancelled = true
        finish(nil, nil, "Cancelled")
    end
    local function poll()
        if handle.finished then return end
        local file = io.open(result_file, "rb")
        if file then
            local contents = file:read("*a")
            file:close()
            local status, err, body = contents:match("^(.-)\n(.-)\n(.*)$")
            finish(tonumber(status), body, err ~= "" and err or nil)
        elseif os.time() > deadline then
            finish(nil, nil, "Request timed out")
        elseif reap(pid) then
            finish(nil, nil, "Network request stopped unexpectedly")
        else
            UIManager:scheduleIn(0.2, poll)
        end
    end
    UIManager:scheduleIn(0.2, poll)
    return handle
end

return Transport
