describe("TradeQueryRateLimiter", function()
	describe("ParseHeader", function()
		-- Pass: Extracts keys/values correctly
		-- Fail: Nil/malformed values, indicating regex failure, breaking policy updates from API
		it("parses basic headers", function()
			local limiter = new("TradeQueryRateLimiter")
			local headers = limiter:ParseHeader("X-Rate-Limit-Policy: test\nRetry-After: 5\nContent-Type: json")
			assert.are.equal(headers["x-rate-limit-policy"], "test")
			assert.are.equal(headers["retry-after"], "5")
			assert.are.equal(headers["content-type"], "json")
		end)
	end)

	describe("ParsePolicy", function()
		-- Pass: Extracts rules/limits/states accurately
		-- Fail: Wrong buckets/windows, indicating parsing bug, enforcing incorrect rates
		it("parses full policy", function()
			local limiter = new("TradeQueryRateLimiter")
			local header = "X-Rate-Limit-Policy: trade-search-request-limit\nX-Rate-Limit-Rules: Ip,Account\nX-Rate-Limit-Ip: 8:10:60,15:60:120\nX-Rate-Limit-Ip-State: 7:10:60,14:60:120\nX-Rate-Limit-Account: 2:5:60\nX-Rate-Limit-Account-State: 1:5:60\nRetry-After: 10"
			local policies = limiter:ParsePolicy(header)
			local policy = policies["trade-search-request-limit"]
			assert.are.equal(policy.ip.limits[10].request, 8)
			assert.are.equal(policy.ip.limits[10].timeout, 60)
			assert.are.equal(policy.ip.state[10].request, 7)
			assert.are.equal(policy.account.limits[5].request, 2)
		end)
	end)

	describe("UpdateFromHeader", function()
		-- Pass: Reduces limits (e.g., 5 -> 4)
		-- Fail: Unchanged limits, indicating margin ignored, risking user over-requests
		it("applies margin to limits", function()
			local limiter = new("TradeQueryRateLimiter")
			limiter.limitMargin = 1
			local header = "X-Rate-Limit-Policy: test\nX-Rate-Limit-Rules: Ip\nX-Rate-Limit-Ip: 5:10:60\nX-Rate-Limit-Ip-State: 4:10:60"
			limiter:UpdateFromHeader(header)
			assert.are.equal(limiter.policies["test"].ip.limits[10].request, 4)
		end)
	end)

	describe("NextRequestTime", function()
		-- Pass: Delays past timestamp
		-- Fail: Allows immediate request, indicating ignored cooldowns, causing 429 errors
		it("blocks on retry-after", function()
			local limiter = new("TradeQueryRateLimiter")
			local now = os.time()
			limiter.policies["test"] = {}
			limiter.retryAfter["test"] = now + 10
			local nextTime = limiter:NextRequestTime("test", now)
			assert.is_true(nextTime > now)
		end)

		-- Pass: Calculates delay from timestamps
		-- Fail: Allows request in limit, indicating state misread, over-throttling or bans
		it("blocks on window limit", function()
			local limiter = new("TradeQueryRateLimiter")
			local now = os.time()
			limiter.policies["test"] = { ["ip"] = { ["limits"] = { ["10"] = { ["request"] = 1, ["timeout"] = 60 } }, ["state"] = { ["10"] = { ["request"] = 1, ["timeout"] = 0 } } } }
			limiter.requestHistory["test"] = { timestamps = {now - 5} }
			limiter.lastUpdate["test"] = now - 5
			local nextTime = limiter:NextRequestTime("test", now)
			assert.is_true(nextTime > now)
		end)
	end)

	describe("AgeOutRequests", function()
		-- Pass: Removes old stamps, decrements to 1
		-- Fail: Stale data persists, indicating aging bug, perpetual blocking
		it("cleans up timestamps and decrements", function()
			local limiter = new("TradeQueryRateLimiter")
			limiter.policies["test"] = { ["ip"] = { ["state"] = { ["10"] = { ["request"] = 2, ["timeout"] = 0, ["decremented"] = nil } } } }
			limiter.requestHistory["test"] = { timestamps = {os.time() - 15, os.time() - 5}, maxWindow=10, lastCheck=os.time() - 10 }
			limiter:AgeOutRequests("test", os.time())
			assert.are.equal(limiter.policies["test"].ip.state["10"].request, 1)
			assert.are.equal(#limiter.requestHistory["test"].timestamps, 1)
		end)
	end)
end)
