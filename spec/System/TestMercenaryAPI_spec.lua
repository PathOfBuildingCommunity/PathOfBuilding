describe("Mercenary API requests", function()
	local json = require("dkjson")
	local originalDownload, originalAPI
	before_each(function()
		newBuild()
		originalDownload = launch.DownloadPage
		originalAPI = main.api
	end)
	after_each(function()
		launch.DownloadPage = originalDownload
		main.api = originalAPI
		while main.popups[1] do main:ClosePopup() end
	end)

	local function api(scopes)
		local instance = new("PoEAPI"):PoEAPI("fixture-token", "fixture-refresh", os.time() + 3600, scopes or "account:characters account:league_accounts")
		instance.UpdateMain = function() end
		return instance
	end

	it("encodes the documented PC, Xbox and Sony league paths", function()
		local instance = api()
		local paths = { }
		instance.DownloadWithRateLimit = function(_, _, path, callback) paths[#paths + 1] = path callback({ }) end
		for _, realm in ipairs({"pc", "xbox", "sony"}) do instance:DownloadLeagueAccount(realm, "Test / League", function() end) end
		assert.same({"/league-account/Test%20%2F%20League", "/league-account/xbox/Test%20%2F%20League", "/league-account/sony/Test%20%2F%20League"}, paths)
	end)

	it("requires the granted scope while retaining character access", function()
		local instance = api("account:characters")
		local errorText
		instance:DownloadLeagueAccount("pc", "Test", function(_, err) errorText = err end)
		assert.equals("Authorize Mercenary access", errorText)
		assert.equals("fixture-token", instance.authToken)
		instance.grantedScopes = nil
		assert.is_false(instance:HasScope("account:league_accounts"))
	end)

	it("refreshes expired tokens and preserves scopes omitted by the refresh response", function()
		local instance = api()
		instance.tokenExpiry = 0
		launch.DownloadPage = function(_, url, callback, params)
			assert.matches("User%-Agent: OAuth pob/", params.header)
			if url:match("oauth/token$") then callback({body = json.encode({access_token = "refreshed", refresh_token = "next", expires_in = 3600})})
			else callback({body = '{"league_account":{"mercenaries":[]}}', header = "HTTP/1.1 200 OK\r\n"}) end
		end
		local result
		instance:DownloadLeagueAccount("pc", "Test", function(body) result = body end)
		assert.is_table(result.league_account)
		assert.is_true(instance:HasScope("account:league_accounts"))
		assert.equals("refreshed", instance.authToken)
	end)

	it("uses server policy names and Retry-After for 429 responses", function()
		local instance, requests = api(), 0
		launch.DownloadPage = function(_, _, callback)
			requests = requests + 1
			callback({body = '{}', header = "HTTP/1.1 429 Too Many Requests\r\nX-Rate-Limit-Policy: league-account-dynamic\r\nRetry-After: 30\r\n"}, "Response code: 429")
		end
		local retry
		instance:DownloadLeagueAccount("pc", "Test", function(_, err, timeNext) assert.equals("Response code: 429", err) retry = timeNext end)
		assert.is_true(retry >= os.time() + 29)
		instance:DownloadLeagueAccount("pc", "Test", function(_, err) assert.equals("Response code: 429", err) end)
		assert.equals(1, requests)
	end)

	it("retries unauthorized responses once and stops after a second 401", function()
		local instance, requests, refreshes = api(), 0, 0
		launch.DownloadPage = function(_, url, callback)
			if url:match("oauth/token$") then
				refreshes = refreshes + 1
				assert.is_true(refreshes <= 1)
				callback({body = json.encode({access_token = "refreshed", refresh_token = "next", expires_in = 3600})})
			else requests = requests + 1 callback({header = "HTTP/1.1 401 Unauthorized\r\n"}, "Response code: 401") end
		end
		local err
		instance:DownloadLeagueAccount("pc", "Test", function(_, errorText) err = errorText end)
		assert.equals("Response code: 401", err)
		assert.equals(2, requests)
		assert.equals(1, refreshes)
	end)

	it("does not restore a logged-out session from a late token refresh", function()
		local instance = api()
		instance.tokenExpiry = 0
		local pending
		launch.DownloadPage = function(_, _, callback) pending = callback end
		instance:DownloadLeagueAccount("pc", "Test", function() end)
		instance:ResetDetails()
		pending({body = json.encode({access_token = "late", refresh_token = "next", expires_in = 3600})})
		assert.is_nil(instance.authToken)
	end)

	it("requests league-account scope with the existing character-import scopes", function()
		local originalLaunch = _G.LaunchSubScript
		local authUrl
		_G.LaunchSubScript = function(_, _, _, url)
			authUrl = url
			return nil
		end
		api():FetchAuthToken(function() end)
		_G.LaunchSubScript = originalLaunch
		assert.matches("account:profile", authUrl)
		assert.matches("account:characters", authUrl)
		assert.matches("account:league_accounts", authUrl)
	end)

	it("labels the action until Mercenary access is granted", function()
		main.api = api("account:characters")
		assert.equals("Authorize Mercenary access", build.importTab.controls.charImportMercenaries.label())
		main.api.grantedScopes = "account:characters account:league_accounts"
		assert.equals("Mercenaries...", build.importTab.controls.charImportMercenaries.label())
	end)

	local function prepareImport()
		local instance = api()
		main.api = instance
		local tab = build.importTab
		tab.controls.charSelect:SetList({{label = "Selected Character", char = { league = "Actual League" }}})
		tab.controls.charSelect:SetSel(1)
		local pending
		instance.DownloadCharacter = function(_, realm, name, callback)
			assert.equals("Selected Character", name)
			pending = callback
		end
		return instance, tab, function(body, err, timeNext) pending(body, err, timeNext) end
	end

	it("uses the fetched character league and active index in the new action", function()
		local instance, tab, complete = prepareImport()
		local captured
		instance.DownloadProfile = function(_, callback) callback({uuid = "fixture-account"}) end
		instance.DownloadLeagueAccount = function(_, realm, league, callback)
			assert.equals("Actual League", league)
			callback({league_account = {mercenaries = {{ name = "Hire" }}}})
		end
		tab.OpenMercenaryImportPopup = function(_, account, source) captured = {account, source} end
		tab.controls.charImportMercenaries.onClick()
		complete({character = {league = "Actual League", active_mercenary_index = 2}})
		assert.equals(2, captured[1].active_mercenary_index)
		assert.equals("fixture-account", captured[2].account)
		assert.is_false(tab.oauthLoading)
	end)

	it("does not open the popup when the league has no Mercenaries", function()
		local instance, tab, complete = prepareImport()
		instance.DownloadProfile = function(_, callback) callback({uuid = "fixture-account"}) end
		instance.DownloadLeagueAccount = function(_, _, _, callback)
			callback({league_account = {mercenaries = { }}})
		end
		tab.OpenMercenaryImportPopup = function() error("Empty roster opened a popup") end
		tab.controls.charImportMercenaries.onClick()
		complete({character = {league = "Actual League"}})
		assert.equals("No Mercenaries found.", tab.oauthErrCode)
		assert.is_false(tab.controls.charImportMercenaries.enabled())
		tab.controls.charSelect:SetList({{label = "Other Character", char = { league = "Other League" }}})
		tab.controls.charSelect:SetSel(1)
		assert.is_true(tab.controls.charImportMercenaries.enabled())
	end)

	for _, change in ipairs({"cancel", "realm", "character", "account", "build", "loadout"}) do
		it("rejects late responses after changing "..change, function()
			local instance, tab, complete = prepareImport()
			instance.DownloadProfile = function() error("Stale response requested account data") end
			tab:DownloadMercenaries()
			if change == "cancel" then tab:CancelMercenaryImport()
			elseif change == "realm" then tab.controls.accountRealm:SetSel(2)
			elseif change == "character" then tab.controls.charSelect:SetList({{label = "Other Character"}})
			elseif change == "account" then instance:ResetDetails()
			elseif change == "build" then newBuild()
			else build.mercenaryTab.profile = {skills = { }} end
			complete({character = {league = "Actual League"}})
		end)
	end
end)
