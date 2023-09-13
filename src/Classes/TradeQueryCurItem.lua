local dkjson = require "dkjson"

local TradeQueryCurItem = newClass("TradeQueryCurItem", function(self, item)
	self.curItem = item
    -- self.itemType = item[3]
	self.hostName = "https://www.pathofexile.com/"
    self.queryModsFilePath = "Data/QueryMods.lua"
    self.leauge = 'Ancestor'
    -- List of items that have a local and a non local option
    self.attrWithLocal = {
        "#% increased Armour, Evasion and Energy Shield",
        "Adds # to # Chaos Damage",
        "#% of Physical Attack Damage Leeched as Mana",
        "#% chance to Poison on Hit",
        "#% of Physical Attack Damage Leeched as Life",
        "#% increased Evasion and Energy Shield",
        "Adds # to # Fire Damage",
        "# to Accuracy Rating",
        "Adds # to # Cold Damage",
        "# to Armour",
        "Adds # to # Lightning Damage",
        "#% increased Armour",
        "# to Evasion Rating",
        "#% increased Armour and Evasion",
        "#% increased Armour and Energy Shield",
        "#% increased Evasion Rating",
        "Adds # to # Physical Damage",
        "#% increased Energy Shield",
        "#% increased Attack Speed",
        "# to maximum Energy Shield",
    }
    -- self.tradeQueryGenerator = newClass('TradeQueryGenerator')
end)

-- Parse the raw item and return the trade url
function TradeQueryCurItem:ParseItem()
    local itemType = self.curItem['baseName']
    local itemIsAccessory = self:CheckIfItemIsAccessory(self.curItem)
    local attributeIDs = {}
    for i, v in pairs(self.curItem.explicitModLines) do
        -- print(v['line'])
        local curStat = self:SanitizeStat(v['line'])
        if not itemIsAccessory then
            if self:TableContains(self.attrWithLocal, curStat) then
                curStat = curStat .. " (Local)"
            end
        end
            for j, w in pairs(v) do
                -- will get stat values from here
            end
        -- print(curStat)
        local curStatID = self:GetExplicitID(curStat)
        -- print(curStatID)
        if (curStatID ~= nil) and (curStatID ~= '') then
            table.insert(attributeIDs, {['id'] = curStatID})
        end
    end
    -- print(dkjson.encode(attributeIDs))
    local endpoint = dkjson.decode(self:GetTradeEndpoint(self:GetTemplate(itemType, attributeIDs)))
    return self:GetTradeUrl(endpoint.id)
end

-- Replace the numbers with # to match the format of the incoming attributees
-- removes any identifier for fractured,crafted ect
function TradeQueryCurItem:SanitizeStat(curStat)
    curStat = curStat:gsub("{.*}", "")
    curStat = curStat:gsub("([1-9][0-9[.][0-9][0-9])", "#")
    curStat = curStat:gsub("([1-9][.][0-9][0-9])", "#")
    curStat = curStat:gsub("([1-9][0-9][0-9])", "#")
    curStat = curStat:gsub("([1-9][0-9])", "#")
    curStat = curStat:gsub("([0-9])", "#")
    curStat = curStat:gsub("([()][#][-][#][)])", "#")
    -- special case, are there more?
    curStat = curStat:gsub("You can apply an additional Curse", "You can apply # additional Curses")
    curStat = curStat:gsub("Bow Attacks fire an additional Arrow", "Bow Attacks fire # additional Arrows")
    curStat = curStat:gsub("Projectiles Pierce an additional Target", "Projectiles Pierce # additional Targets")
    curStat = curStat:gsub("Has 1 Abyssal Socket", "Has # Abyssal Sockets")
    return curStat
end

-- get the id's of implicit modifier if decided to do this
function TradeQueryCurItem:GetImplicitID(mod)
    local tradeMods = LoadModule(self.queryModsFilePath)
    for i, v in pairs(tradeMods['Implicit']) do
        if v['tradeMod']['text'] == mod then
            return v['tradeMod']['id']
        end
    end
    return nil
end

-- get the id's of explicit modifiers
function TradeQueryCurItem:GetExplicitID(mod)
    local tradeMods = self:FetchStats()
    -- for i, v in pairs(tradeMods) do
    --     for j, w in pairs(v) do
    --         if w['tradeMod']['text'] == mod then
    --             return w['tradeMod']['id']:gsub('implicit', 'explicit')
    --         end
    --     end
    -- end
    for i=1, #tradeMods.results do
        if tradeMods.results[i].text == mod then
            return tradeMods.results[i].id
        end
    end
    return nil
end

-- returns true/false if table contains needle
function TradeQueryCurItem:TableContains(haystack, needle)
    for i = 1, #haystack do
        if haystack[i] == needle then
            return true
        end
    end
    return false
end

-- check if item is an accessory, need this to know if needing to use the Local option or not
function TradeQueryCurItem:CheckIfItemIsAccessory(item)
    if (item.base.type == 'Ring') or (item.base.type == 'Amulet') or (item.base.type == 'Belt') then
        return true
    else
        return false
    end
end

-- template for getting the url endpoint
function TradeQueryCurItem:GetTemplate(type, attributeeIDs)
    local template = {
        ["query"] = {
          ["status"] = {
            ["option"] = "online"
          },
          ["type"] = type,
          ["stats"] = {
            {
              ["type"] = "and",
              ["filters"] = attributeeIDs
            }
        },
          ["filters"] = {
            ["type_filters"] = {
      
            }
          }
        },
        ["sort"] = {
          ["price"] = "asc"
        }
      }
    return dkjson.encode(template)
end

-- passes the template to receive the endpoint
function TradeQueryCurItem:GetTradeEndpoint(template)
    local tradeLink = ""
	local easy = common.curl.easy()
	easy:setopt_url("https://www.pathofexile.com/api/trade/search/" .. self.leauge)
	easy:setopt_useragent("Path of Building/" .. launch.versionNumber .. "test")
    local header = {"Content-Type: application/json"}
    easy:setopt(common.curl.OPT_HTTPHEADER, header)
    easy:setopt(common.curl.OPT_POST, true)
    easy:setopt(common.curl.OPT_POSTFIELDS, template)
    easy:setopt(common.curl.OPT_ACCEPT_ENCODING, "")
	easy:setopt_writefunction(function(data)
		tradeLink = tradeLink..data
		return true
	end)
	easy:perform()
	easy:close()
    return tradeLink
end

-- appends the endpoint to the default trade url
function TradeQueryCurItem:GetTradeUrl(endpoint)
    return 'https://www.pathofexile.com/trade/search/'.. self.leauge .. '/' .. endpoint;
end


-- hit the api to get the item attributees
function TradeQueryCurItem:FetchStats()
    local queryModsFile = io.open('Data/RawQueryMods.lua', 'r')
    local rawQueryMods = ''
    if queryModsFile ~= nil then
        rawQueryMods = LoadModule('Data/RawQueryMods.lua')
        return rawQueryMods
    end
	local tradeStats = ""
	local easy = common.curl.easy()
	easy:setopt_url("https://www.pathofexile.com/api/trade/data/stats")
	easy:setopt_useragent("Path of Building/" .. launch.versionNumber .. "test")
	easy:setopt_writefunction(function(data)
		tradeStats = tradeStats..data
		return true
	end)
	easy:perform()
	easy:close()
    self:GenerateRawQueryMods(tradeStats)
	return LoadModule('Data/RawQueryMods.lua')
end

function TradeQueryCurItem:GenerateRawQueryMods(tradeStats)
    tradeStats:gsub("\n", " ")
	local tradeQueryStatsParsed = dkjson.decode(tradeStats)
    -- ConPrintTable(tradeQueryStatsParsed)
    local queryModsFile = io.open('Data/RawQueryMods.lua', 'w')
    queryModsFile:write("-- This file is automatically generated, do not edit!\n-- Stat data (c) Grinding Gear Games\n\n")
    queryModsFile:write('return { ["results"] = {')
    for i=1, #tradeQueryStatsParsed.result[2]['entries'] do
        queryModsFile:write('{')
        queryModsFile:write('["id"] = "'.. stringify(tradeQueryStatsParsed.result[2]['entries'][i].id):gsub('"%a', '[[')..'",')
        queryModsFile:write('["text"] = [['.. stringify(tradeQueryStatsParsed.result[2]['entries'][i].text):gsub('"%a', '[[')..']],')
        queryModsFile:write('["type"] = "'.. stringify(tradeQueryStatsParsed.result[2]['entries'][i].type):gsub('"%a', '[[')..'",')
        queryModsFile:write('},')
        queryModsFile:write('\r\n')
    end
    queryModsFile:write("}}")
	queryModsFile:close()
end

