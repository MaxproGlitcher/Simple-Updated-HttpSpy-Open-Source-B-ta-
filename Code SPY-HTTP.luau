local HttpService = game:GetService("HttpService")
local lastUrl = ""

local function logFull(method, url, reqBody, reqHeaders, resBody, resStatus)
    if lastUrl == url then return end
    lastUrl = url

    print("--- [ HTTP EVENT ] ---")
    warn(string.format("📡 %s: %s", method:upper(), tostring(url)))
    
    if reqHeaders then 
        print("➡️  Headers:", HttpService:JSONEncode(reqHeaders)) 
    end
    
    if reqBody and #tostring(reqBody) > 0 then 
        print("➡️  Body:", tostring(reqBody)) 
    end

    print("⬅️  Status:", tostring(resStatus or "N/A"))
    
    local displayResponse = tostring(resBody or "No Response")
    if #displayResponse > 1000 then
        displayResponse = displayResponse:sub(1, 1000) .. "... (Big File)"
    end
    print("⬅️  Response:", displayResponse)
    print("----------------------")
    
    task.delay(0.1, function() lastUrl = "" end)
end

-- Hook  'request' / 'http_request' (Executor level)
local oldReq
oldReq = hookfunction(request or http_request, function(options)
    if not options or not options.Url then return oldReq(options) end
    
    local response = oldReq(options)
    
    logFull(
        options.Method or "GET", 
        options.Url, 
        options.Body, 
        options.Headers, 
        response.Body, 
        response.StatusCode
    )
    
    return response
end)

--  Hook 'HttpGet/Post' (Game level)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method:find("HttpGet") and args[1] then
        local url = args[1]
        local response = oldNamecall(self, ...)
        logFull("GET (Native)", url, nil, nil, response, 200)
        return response
    elseif method:find("HttpPost") and args[1] then
        local url = args[1]
        local body = args[2]
        local response = oldNamecall(self, ...)
        logFull("POST (Native)", url, body, nil, response, 200)
        return response
    end
    
    return oldNamecall(self, ...)
end)

print("Loaded")
