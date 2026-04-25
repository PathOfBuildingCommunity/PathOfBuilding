describe("BuildSiteTools", function()
	local downloadCalls
	local origDownloadPage

	before_each(function()
		downloadCalls = {}
		origDownloadPage = launch.DownloadPage
		launch.DownloadPage = function(_self, url, callback, params)
			table.insert(downloadCalls, { url = url, callback = callback, params = params })
		end
	end)

	after_each(function()
		launch.DownloadPage = origDownloadPage
	end)

	describe("DownloadBuild", function()
		-- Pass: Returns the payload, no DownloadPage call
		-- Fail: HTTP fetch made or wrong data returned, breaking offline imports
		it("returns the inline build code for pob://code/ without fetching", function()
			local result = {}
			buildSites.DownloadBuild("pob://code/ABCxyz_-123", nil, function(isSuccess, data, link)
				result.isSuccess = isSuccess
				result.data = data
				result.link = link
			end)
			assert.is_true(result.isSuccess)
			assert.are.equal("ABCxyz_-123", result.data)
			assert.are.equal("pob://code/ABCxyz_-123", result.link)
			assert.are.equal(0, #downloadCalls)
		end)

		-- Pass: Routes to https://pobb.in/pob/abcd
		-- Fail: No fetch made, breaking existing pobb.in imports
		it("preserves existing pob://pobbin/ handling", function()
			buildSites.DownloadBuild("pob://pobbin/abcd", nil, function() end)
			assert.are.equal(1, #downloadCalls)
			assert.are.equal("https://pobb.in/pob/abcd", downloadCalls[1].url)
		end)

		-- Pass: Returns "Download information not found"
		-- Fail: Accepts the URI, indicating regex over-match, passing junk downstream
		it("rejects unknown providers", function()
			local result = {}
			buildSites.DownloadBuild("pob://unknown/xyz", nil, function(isSuccess, data)
				result.isSuccess = isSuccess
				result.data = data
			end)
			assert.is_false(result.isSuccess)
			assert.are.equal("Download information not found", result.data)
			assert.are.equal(0, #downloadCalls)
		end)

		-- Pass: Empty payload rejected
		-- Fail: Empty string reaches base64.decode
		it("requires a non-empty inline payload", function()
			local result = {}
			buildSites.DownloadBuild("pob://code/", nil, function(isSuccess, data)
				result.isSuccess = isSuccess
				result.data = data
			end)
			assert.is_false(result.isSuccess)
			assert.are.equal("Download information not found", result.data)
			assert.are.equal(0, #downloadCalls)
		end)

		-- Pass: Spaces and punctuation rejected
		-- Fail: Non-base64 chars reach the decoder, failing with a cryptic error
		it("rejects payloads outside the base64url alphabet", function()
			local result = {}
			buildSites.DownloadBuild("pob://code/has spaces!", nil, function(isSuccess, data)
				result.isSuccess = isSuccess
				result.data = data
			end)
			assert.is_false(result.isSuccess)
			assert.are.equal("Download information not found", result.data)
			assert.are.equal(0, #downloadCalls)
		end)

		-- Pass: ABCD, ABC=, AB== all accepted
		-- Fail: Padded codes rejected, breaking imports from emitters that pad
		it("accepts optional trailing base64 padding", function()
			for _, code in ipairs({ "ABCD", "ABC=", "AB==" }) do
				local data
				buildSites.DownloadBuild("pob://code/" .. code, nil, function(_, d) data = d end)
				assert.are.equal(code, data)
			end
		end)

		-- Pass: =abc, a=bc, AAAA=== rejected
		-- Fail: Bad padding reaches the decoder
		it("rejects misplaced '=' padding", function()
			for _, link in ipairs({ "pob://code/=abc", "pob://code/a=bc", "pob://code/AAAA===" }) do
				local result = {}
				buildSites.DownloadBuild(link, nil, function(isSuccess, data)
					result.isSuccess = isSuccess
					result.data = data
				end)
				assert.is_false(result.isSuccess, "should reject " .. link)
				assert.are.equal("Download information not found", result.data)
			end
		end)
	end)

	describe("ParseImportLinkFromURI", function()
		-- Pass: Returns nil
		-- Fail: Returns a URL, attaching the build to a site that wasn't used
		it("returns nil for pob://code/", function()
			assert.is_nil(buildSites.ParseImportLinkFromURI("pob://code/abc"))
		end)

		-- Pass: Returns https://pobb.in/abc
		-- Fail: Regression in existing site URI parsing
		it("still resolves pob://pobbin/", function()
			assert.are.equal("https://pobb.in/abc", buildSites.ParseImportLinkFromURI("pob://pobbin/abc"))
		end)
	end)
end)
