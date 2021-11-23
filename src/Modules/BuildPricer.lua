-- Path of Building
--
-- Module: Build Pricer
-- Provides method to look up prices of URL-specified items in PoE's Trade
--

local bp = { }

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

function bp.search_item(json_data, controls, index)
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
                --local foo = io.open("../url_dump.txt", "w")
                --foo:write(response)
                --foo:close()

                local response_1 = bp.ProcessJSON(response)
                if not response_1 then
                    return
                end
                local res_lines = ""
                if #response_1.result == 0 then
                    controls.whisper:SetText("NO RESULTS FOUND")
                    return
                end
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
                                controls['name'..index]:SetText(trade_entry.item.name.." "..trade_entry.item.typeLine)
                                controls['priceAmount'..index]:SetText(trade_entry.listing.price.amount)
                                controls['priceLabel'..index]:SetText(trade_entry.listing.price.currency)
                                -- TODO: add support for UTF8
                                controls['whisper'..index]:SetText(trade_entry.listing.whisper)
                                local implicitMods = ""
                                if trade_entry.item.implicitMods then
                                    for _, mod in ipairs(trade_entry.item.implicitMods) do
                                        implicitMods = implicitMods .. mod .. ", "
                                    end
                                    implicitMods = implicitMods:sub(1, -3)
                                    controls['implicitMods'..index]:SetText(implicitMods)
                                end
                                local explicitMods = ""
                                if trade_entry.item.explicitMods then
                                    for _, mod in ipairs(trade_entry.item.explicitMods) do
                                        explicitMods = explicitMods .. mod .. ", "
                                    end
                                    explicitMods = explicitMods:sub(1, -3)
                                    controls['explicitMods'..index]:SetText(explicitMods)
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

function bp.public_trade(url, controls, index)
    local id = LaunchSubScript([[
        local url = ...
        local curl = require("lcurl.safe")
        local page = ""
        local easy = curl.easy()
        easy:setopt{
            url = url,
            httpheader = {'User-Agent: Path of Building/2.17 (contact: pob@mailbox.org)'}
        }
        easy:setopt_writefunction(function(data)
            page = page..data
            return true
        end)
        easy:perform()
        easy:close()
        return page
    ]], "", "", url)
    if id then
        launch:RegisterSubScript(id, function(response, errMsg)
            if errMsg then
                return "TRADE ERROR", "Error: "..errMsg
            else
                --local foo = io.open("../public_dump.txt", "w")
                --foo:write(response)
                --foo:close()

                local trimmed = response:sub(1, -2)
                local json_query = trimmed .. ', "sort": {"price": "asc"}}'

                --local foo = io.open("../test.txt", "w")
                --foo:write(json_query)
                --foo:close()
                bp.search_item(json_query, controls, index)
            end
        end)
    end
end

function bp.runBuildPricer(build)
    local gear_URIs = {
        "https://www.pathofexile.com/api/trade/search/2PEkepGFk",
        "https://www.pathofexile.com/api/trade/search/opO8m3YIl",
    }

    local pane_height = 600
    local pane_width = 1600
    local controls = { }
    local top_pane_alignment_ref = nil
    local top_pane_alignment_width = -612
    local top_pane_alignment_height = pane_height - 570
    for cnt, uri in ipairs(gear_URIs) do
        local str_cnt = tostring(cnt)
        controls['name'..str_cnt] = new("EditControl", top_pane_alignment_ref, top_pane_alignment_width, top_pane_alignment_height, 360, 20, "", "Name", "%Z")
        controls['name'..str_cnt].enabled = function()
            return #controls['name'..str_cnt].buf > 0
        end
        controls['priceAmount'..str_cnt] = new("EditControl", {"TOPLEFT",controls['name'..str_cnt],"TOPLEFT"}, 360 + 16, 0, 120, 20, "", "Price", "%Z")
        controls['priceAmount'..str_cnt].enabled = function()
            return #controls['priceAmount'..str_cnt].buf > 0
        end
        controls['priceLabel'..str_cnt] = new("EditControl", {"TOPLEFT",controls['priceAmount'..str_cnt],"TOPLEFT"}, 120 + 16, 0, 120, 20, "", "Currency", "%Z")
        controls['priceLabel'..str_cnt].enabled = function()
            return #controls['priceLabel'..str_cnt].buf > 0
        end
        controls['uri'..str_cnt] = new("EditControl", {"TOPLEFT",controls['priceLabel'..str_cnt],"TOPLEFT"}, 120 + 16, 0, 500, 20, "Trade Site URL", nil, "^%C\t\n", nil, nil, 16)
        controls['uri'..str_cnt]:SetText(uri)
        controls['priceButton'..str_cnt] = new("ButtonControl", {"TOPLEFT",controls['uri'..str_cnt],"TOPLEFT"}, 500 + 16, 0, 100, 20, "Price Item", function()
            bp.public_trade(uri, controls, str_cnt)
        end)
        controls['importButton'..str_cnt] = new("ButtonControl", {"TOPLEFT",controls['priceButton'..str_cnt],"TOPLEFT"}, 100 + 16, 0, 100, 20, "Import Item", function()
            ConPrintf("TODO - import item found into build")
        end)
        controls['importButton'..str_cnt].enabled = function()
            return #controls['priceAmount'..str_cnt].buf > 0
        end

        controls['implicitMods'..str_cnt] = new("EditControl", {"TOPLEFT",controls['name'..str_cnt],"TOPLEFT"}, 0, 24, pane_width - 16, 20, "", "Implicits", "%Z")
        controls['implicitMods'..str_cnt].enabled = function()
            return #controls['implicitMods'..str_cnt].buf > 0
        end
        controls['explicitMods'..str_cnt] = new("EditControl", {"TOPLEFT",controls['implicitMods'..str_cnt],"TOPLEFT"}, 0, 24, pane_width - 16, 20, "", "Explicits", "%Z")
        controls['explicitMods'..str_cnt].enabled = function()
            return #controls['explicitMods'..str_cnt].buf > 0
        end
        controls['whisper'..str_cnt] = new("EditControl", {"TOPLEFT",controls['explicitMods'..str_cnt],"TOPLEFT"}, 0, 24, pane_width - 16, 20, "", "Whisper", "%Z")
        controls['whisper'..str_cnt].enabled = function()
            return #controls['whisper'..str_cnt].buf > 0
        end
        top_pane_alignment_ref = {"TOPLEFT",controls['whisper'..str_cnt],"TOPLEFT"}
        top_pane_alignment_width = 0
        top_pane_alignment_height = 48
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
end

return bp