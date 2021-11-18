-- Path of Building
--
-- Module: Build Pricer
-- Provides method to look up prices of URL-specified items in PoE's Trade
--

local bp = { }

local BuildPricerClass = newClass("BuildPricer", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

    	-- Stage: input POESESSID
	self.controls.sessionHeader = new("LabelControl", {"TOPLEFT",self.controls.sectionCharImport,"TOPLEFT"}, 6, 40, 200, 14)
	self.controls.sessionHeader.label = function()
		return [[
^7The list of characters on ']]..self.controls.accountName.buf..[[' couldn't be retrieved. This may be because:
1. The account name is wrong, or
2. The account's privacy settings hide the characters tab (this is the default setting).
If this is your account, you can either:
1. Change your privacy settings to show you characters tab and then retry, or
2. Enter a valid POESESSID below.
You can get this from your web browser's cookies while logged into the Path of Exile website.
		]]
	end
	self.controls.sessionHeader.shown = function()
		return self.charImportMode == "GETSESSIONID"
	end
end)

function BuildPricerClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self.controls.edit:Undo()
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.controls.edit:Redo()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	--self.modFlag = (self.lastContent ~= self.controls.edit.buf)
end

function bp.ProcessJSON(json)
	local func, errMsg = loadstring("return "..jsonToLua(json))
	if errMsg then
		return nil, errMsg
	end
	setfenv(func, { }) -- Sandbox the function just in case
	local data = func()
	if type(data) ~= "table" then
		return nil, "Return type is not a table"
	end
	return data
end

function bp.blah(json_data, outputWhisper, outputImplicitMods)
    outputImplicitMods:SetText("")
    local id = LaunchSubScript([[
        local json_data = ...
        local curl = require("lcurl.safe")
        local page = ""
        local easy = curl.easy()
        easy:setopt{
            url = "https://www.pathofexile.com/api/trade/search/Scourge",
            post = true,
            httpheader = {'Content-Type: application/json', 'Accept: application/json', 'User-Agent: Path of Building/2.17 (contact: pob@mailbox.org)'},
            postfields = json_data
        }
        easy:setopt_writefunction(function(data)
            page = page..data
            return true
        end)
        easy:perform()
        easy:close()
        return page
    ]], "", "", json_data)
    if id then
        launch:RegisterSubScript(id, function(response, errMsg)
            if errMsg then
                return "TRADE ERROR", "Error: "..errMsg
            else
                local foo = io.open("../url_dump.txt", "w")
                foo:write(response)
                foo:close()

                local response_1 = bp.ProcessJSON(response)
                if not response_1 then
                    return
                end
                local res_lines = ""
                for index, res_line in ipairs(response_1.result) do
                    if index < 11 then
                        res_lines = res_lines .. res_line .. ","
                    else
                        break
                    end
                end
                res_lines = res_lines:sub(1, -2)
                local fetch_url = "https://www.pathofexile.com/api/trade/fetch/"..res_lines.."?query="..response_1.id
                local id2 = LaunchSubScript([[
                    local fetch_url = ...
                    local curl = require("lcurl.safe")
                    local page = ""
                    local easy = curl.easy()
                    easy:setopt{
                        url = fetch_url,
                        httpheader = {'User-Agent: Path of Building/2.17 (contact: pob@mailbox.org)'}
                    }
                    easy:setopt_writefunction(function(data)
                        page = page..data
                        return true
                    end)
                    easy:perform()
                    easy:close()
                    return page
                ]], "", "", fetch_url)
                if id2 then
                    local ret_data = nil
                    launch:RegisterSubScript(id2, function(response2, errMsg)
                        if errMsg then
                            ConPrintf("TRADE ERROR", "Error:\n"..errMsg)
                        else
                            local foo = io.open("../url_dump_2.txt", "w")
                            foo:write(response2)
                            foo:close()
                            local response_2 = bp.ProcessJSON(response2)
                            if not response_2 then
                                return
                            end
                            for trade_indx, trade_entry in ipairs(response_2.result) do
                                --ConPrintf(prettyPrintTable(trade_entry))
                                outputWhisper:SetText(trade_entry.listing.whisper)
                                local implicitMods = ""
                                if trade_entry.item.implicitMods then
                                    for _, mod in ipairs(trade_entry.item.implicitMods) do
                                        implicitMods = implicitMods .. mod .. ", "
                                    end
                                    implicitMods:sub(1, -4)
                                    outputImplicitMods:SetText(implicitMods)
                                end
                                return
                            end
                        end
                    end)
                else
                    return
                end
            end
        end)
    end
end

function bp.runBuildPricer(build)
    local pane_height = 500
    local pane_width = 1200
    local controls = { }
    controls.whisper = new("EditControl", nil, 0, pane_height - 470, 1200 - 16, 16, "", "Whisper", "%Z")
    controls.whisper.enabled = function()
		return #controls.whisper.buf > 0
	end
    controls.implicitMods = new("EditControl", {"TOPLEFT",controls.whisper,"TOPLEFT"}, 0, 32, 1200 - 16, 16, "", "Implicits", "%Z")
    controls.implicitMods.enabled = function()
		return #controls.implicitMods.buf > 0
	end
    controls.close = new("ButtonControl", nil, 0, pane_height - 30, 90, 20, "Done", function()
		main:ClosePopup()
	end)
    main:OpenPopup(pane_width, pane_height, "Build Pricer", controls)

    -- TODO: Determine which build spec is used so we can do this per spec
    --[[
    local specs = build.specs
    if specs then
        for specId, spec in ipairs(specs) do
            ConPrintf("SpecID: " .. tostring(specId))
        end
    end
    --]]

    json_query = '{"query": { "status": { "option": "online" }, "name": "Inspired Learning", "type": "Crimson Jewel", "stats": [{"type": "and", "filters": []}], "filters": {} }, "sort": {"price": "asc"} }'
    bp.blah(json_query, controls.whisper, controls.implicitMods)
end

return bp