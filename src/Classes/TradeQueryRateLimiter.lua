-- Path of Building
--
-- Module: Trade Site Rate Limiter
-- Manages rate limits for trade API
-- https://www.pathofexile.com/forum/view-thread/2079853
--

---@class TradeQueryRateLimiter
local TradeQueryRateLimiterClass = newClass("TradeQueryRateLimiter", function(self)
    -- policies_sample = {
    -- --   label: policy
    --     ["trade-search-request-limit"] = {
    -- --       label: rule   
    --         ["Ip"] = {
    --             ["state"] = {
    --                 ["60"]  = {["timeout"] = 0,    ["request"] = 1},
    --                 ["300"] = {["timeout"] = 0,    ["request"] = 1},
    --                 ["10"]  = {["timeout"] = 0,    ["request"] = 1}
    --             },
    --             ["limits"] = {
    --                 ["60"]  = {["timeout"] = 120,  ["request"] = 15},
    --                 ["300"] = {["timeout"] = 1800, ["request"] = 60},
    --                 ["10"]  = {["timeout"] = 60,   ["request"] = 8}
    --             }
    --         },
    --         ["Account"] = {
    --             ["state"] = {
    --                 ["5"]   = {["timeout"] = 0,    ["request"] = 1}
    --             },
    --             ["limits"] = {
    --                 ["5"]   = {["timeout"] = 60,   ["request"] = 3}
    --             }
    --         }
    --     }
    -- }
    self.policies = {}
    self.retryAfter = {}
    self.lastUpdate = {}
    self.requestHistory = {}
    -- leave this much safety margin on limits for external use (browser, trade app)
    self.limitMargin = 1
    -- convenient name lookup, can be extended
    self.policyNames = {
        ["search"] = "trade-search-request-limit",
        ["fetch"] = "trade-fetch-request-limit"
    }
    self.delayCache = {}
    self.requestId = 0
    -- we are tracking ongoing requests to update the rate limits state when 
    -- the last request is finished since this is a reliable sync point. (no pending modifications on state)
    -- Otherwise we are managing our local state and updating only if the response
    -- state shows more requests than expected (external requests)
    self.pendingRequests = {
        ["trade-search-request-limit"] = {},
        ["trade-fetch-request-limit"] = {}
    }
end)

function TradeQueryRateLimiterClass:GetPolicyName(key)
    return self.policyNames[key]
end

function TradeQueryRateLimiterClass:ParseHeader(headerString)
    local headers = {}
    for k, v in headerString:gmatch("([%a%d%-]+): ([%g ]+)") do
        if k == nil then error("Unparsable Header") end
        headers[k:lower()] = v
    end
    return headers
end

function TradeQueryRateLimiterClass:ParsePolicy(headerString) 
    local policies = {}
    local headers = self:ParseHeader(headerString)
    local policyName = headers["x-rate-limit-policy"]
    policies[policyName] = {}
    local retryAfter = headers["retry-after"]
    if retryAfter then
        policies[policyName].retryAfter = os.time() + retryAfter
    end
    local ruleNames = {}
    for match in headers["x-rate-limit-rules"]:gmatch("[^,]+") do
        ruleNames[#ruleNames+1] = match:lower()
    end
    for _, ruleName in pairs(ruleNames) do
        policies[policyName][ruleName] = {}
        local properties = {
            ["limits"] = "x-rate-limit-"..ruleName,
            ["state"] = "x-rate-limit-"..ruleName.."-state",
        }
        for key, headerKey in pairs(properties) do
            policies[policyName][ruleName][key] = {}
            local headerValue = headers[headerKey]
            for bucket in headerValue:gmatch("[^,]+") do -- example 8:10:60,15:60:120,60:300:1800
                local next = bucket:gmatch("[^:]+") -- example 8:10:60
                local request, window, timeout = tonumber(next()), tonumber(next()), tonumber(next())
                policies[policyName][ruleName][key][window] = {
                    ["request"] = request,
                    ["timeout"] = timeout
                }
            end
        end
    end
    return policies
end

function TradeQueryRateLimiterClass:UpdateFromHeader(headerString)
    local newPolicies = self:ParsePolicy(headerString)
    for policyKey, policyValue in pairs(newPolicies) do
        if self.requestHistory[policyKey] == nil then
            self.requestHistory[policyKey] = { timestamps = {} }
        end
        if policyValue.retryAfter then
            self.retryAfter[policyKey] = policyValue.retryAfter
            policyValue.retryAfter = nil
        end
        if self.limitMargin > 0 then
            newPolicies = self:ReduceLimits(self.limitMargin, newPolicies)
        end
        if self.policies[policyKey] == nil or #self.pendingRequests[policyKey] == 0 then
            self.policies[policyKey] = policyValue
        else
            for rule, ruleValue in pairs(policyValue) do
                for window, state in pairs(ruleValue.state) do
                    local oldState = self.policies[policyKey][rule]["state"][window]
                    if state.request > oldState.request then
                        oldState.request = state.request
                    end
                end
            end
        end
        self.lastUpdate[policyKey] = os.time()
        -- calculate maxWindow sizes for requestHistory tables
        local maxWindow = 0
        for _, rule in pairs(policyValue) do
            for window, _ in pairs(rule.limits) do
                maxWindow = math.max(maxWindow, window)
            end
        end
        self.requestHistory[policyKey].maxWindow = maxWindow
    end
end

function TradeQueryRateLimiterClass:NextRequestTime(policy, time)
    local now = time or os.time()
    local nextTime = now
    if self.policies[policy] == nil then
        if self.requestHistory[policy] and #self.requestHistory[policy].timestamps > 0 then
            -- a request has been made and we are waiting for the response to parse limits, block requests using a long cooldown (PoE2 release date)
            -- practically blocking indefinitely until rate limits are initialized
            return 1956528000
        else
            -- first request, don't block to acquire rate limits from first response
            return now
        end
    end
    if self.retryAfter[policy] and self.retryAfter[policy] >= now then
        nextTime = math.max(nextTime, self.retryAfter[policy])
        return nextTime
    end
    self:AgeOutRequests(policy)
    for _, rule in pairs(self.policies[policy]) do
        for window, _ in pairs(rule.limits) do
            if rule.state[window].timeout > 0 then
                --an extra second is added to the time calculations here and below in order to avoid problems caused by the low resolution of os.time()
                nextTime = math.max(nextTime, self.lastUpdate[policy] + rule.state[window].timeout + 1)
            end
            if rule.state[window].request >= rule.limits[window].request then
                -- reached limit, calculate next request time
                -- find oldest timestamp in window
                local oldestRequestIdx = 0
                for _, timestamp in pairs(self.requestHistory[policy].timestamps) do
                    if timestamp >= now - window then
                        oldestRequestIdx = oldestRequestIdx + 1
                    else
                        break
                    end
                end
                if oldestRequestIdx == 0 then 
                    -- state reached limit but we don't have any recent timestamps (external factors)
                    nextTime = math.max(nextTime, self.lastUpdate[policy] + rule.limits[window].timeout + 1)
                else
                    -- the expiration time of oldest timestamp in the window
                    local nextAvailableTime = self.requestHistory[policy].timestamps[oldestRequestIdx] + window + 1
                    nextTime = math.max(nextTime, nextAvailableTime)
                end
            end
        end
    end
    return nextTime
end

function TradeQueryRateLimiterClass:InsertRequest(policy, timestamp, time)
    local now = time or os.time()
    timestamp = timestamp or now
    if self.requestHistory[policy] == nil then
        self.requestHistory[policy] = { timestamps = {} }
    end
    local insertIndex = 1
    for i, v in ipairs(self.requestHistory[policy].timestamps) do
        if timestamp >= v then
            insertIndex = i
            break
        end
    end
    table.insert(self.requestHistory[policy].timestamps, insertIndex, timestamp)
    if self.policies[policy] then
        for _, rule in pairs(self.policies[policy]) do
            for _, window in pairs(rule.state) do
                window.request = window.request + 1
            end
        end
        self.lastUpdate[policy] = now
    end
    local requestId = self.requestId
    self.requestId = self.requestId + 1
    table.insert(self.pendingRequests[policy], requestId)
    return requestId 
end

function TradeQueryRateLimiterClass:FinishRequest(policy, requestId)
    if self.pendingRequests[policy] then
        for index, value in ipairs(self.pendingRequests[policy]) do
            if value == requestId then
                table.remove(self.pendingRequests[policy], index)
            end
        end
    end
end

function TradeQueryRateLimiterClass:AgeOutRequests(policy, time)
    local now = time or os.time()
    local requestHistory = self.requestHistory[policy]
    requestHistory.lastCheck = requestHistory.lastCheck or now
    if (requestHistory.lastCheck == now) then
        return
    end
    for i = #requestHistory.timestamps, 1 , -1 do
        local timestamp = requestHistory.timestamps[i]
        for _, rule in pairs(self.policies[policy]) do
            for window, windowValue in pairs(rule.state) do
                if timestamp >= (requestHistory.lastCheck - window) and timestamp < (now - window) then
                    -- timestamp that used to be in the window on last check
                    windowValue.request = math.max(windowValue.request - 1, 0)
                end
            end
        end
        if timestamp < now - requestHistory.maxWindow then
            table.remove(requestHistory.timestamps, i)
        end
    end
    requestHistory.lastCheck = now
end

-- Reduce limits visible to pob so the user can safely interact with the trade site
function TradeQueryRateLimiterClass:ReduceLimits(margin, policies)
    for _, policy in pairs(policies) do
        for _, rule in pairs(policy) do
            for _, window in pairs(rule.limits) do
                window.request = math.max(window.request - margin, 1)
            end
        end
    end
    return policies
end
