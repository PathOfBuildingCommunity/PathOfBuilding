describe("PoEAPI auth", function()
	local originalLaunchSubScript
	local originalDownloadPage
	local originalSubScripts

	before_each(function()
		originalLaunchSubScript = _G.LaunchSubScript
		originalDownloadPage = launch.DownloadPage
		originalSubScripts = launch.subScripts
		launch.subScripts = {}
	end)

	after_each(function()
		_G.LaunchSubScript = originalLaunchSubScript
		launch.DownloadPage = originalDownloadPage
		launch.subScripts = originalSubScripts
	end)

	it("passes token exchange errors to the auth callback #auth", function()
		local authState
		_G.LaunchSubScript = function(_, _, _, authUrl)
			authState = authUrl:match("state=([^&]+)")
			return 123
		end
		launch.DownloadPage = function(_, url, callback)
			assert.are.equals("https://www.pathofexile.com/oauth/token", url)
			callback(nil, "SSL connect error")
		end

		local api = new("PoEAPI"):PoEAPI()
		local callbackArgs
		api:FetchAuthToken(function(errMsg)
			callbackArgs = {
				errMsg = errMsg,
			}
		end)

		assert.is_not_nil(authState)
		assert.is_not_nil(launch.subScripts[123])
		launch.subScripts[123].callback("auth-code", nil, authState, 12345)

		assert.are.equals("SSL connect error", callbackArgs.errMsg)
		assert.is_nil(api.authToken)
	end)

	it("reports OAuth state mismatches without exchanging a token", function()
		_G.LaunchSubScript = function()
			return 123
		end
		launch.DownloadPage = function()
			error("token exchange should not run for mismatched OAuth state")
		end

		local api = new("PoEAPI"):PoEAPI()
		local callbackArgs
		api:FetchAuthToken(function(errMsg)
			callbackArgs = {
				errMsg = errMsg,
			}
		end)

		assert.is_not_nil(launch.subScripts[123])
		launch.subScripts[123].callback("auth-code", nil, "wrong-state", 12345)

		assert.are.equals("OAuth state mismatch", callbackArgs.errMsg)
		assert.is_nil(api.authToken)
	end)
	it("stays usable after an error", function()
		local api = new("PoEAPI"):PoEAPI("token", "refresh", os.time() + 3600)

		-- Drive the network layer directly so we bypass ValidateAuth/token
		-- refresh and exercise only DownloadWithRateLimit's limiter bookkeeping.
		-- First attempt fails transiently (dropped connection, no HTTP headers),
		-- second attempt succeeds.
		local attempts = 0
		api.DownloadWithRefresh = function(_, _, onComplete)
			attempts = attempts + 1
			if attempts == 1 then
				onComplete(nil, "SSL connect error")
			else
				onComplete({
					body = '{"characters":[]}',
					header = "HTTP/1.1 200 OK\nX-Rate-Limit-Policy: character-list-request-limit\n",
				}, nil)
			end
		end

		local firstErr
		api:DownloadCharacterList("pc", function(_, err) firstErr = err end)
		assert.are.equals("SSL connect error", firstErr)

		local secondErr
		api:DownloadCharacterList("pc", function(_, err) secondErr = err end)

		-- The second request should reach the network again and succeed. Under
		-- the bug it is short-circuited before DownloadWithRefresh is ever
		-- called, so attempts stays at 1 and secondErr is "Response code: 429".
		assert.are.equals(2, attempts)
		assert.is_nil(secondErr)
	end)
end)
