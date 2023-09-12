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
    local itemType = ''
    for i, v in pairs(self.curItem.baseLines) do
        print(v['line'])
        itemType = v['line']
    end
    local itemIsAccessory = self:CheckIfItemIsAccessory(itemType)
    local attribuitIDs = {}
    for i, v in pairs(self.curItem.explicitModLines) do
        print(v['line'])
        local curStat = self:SanitizeStat(v['line'])
        print(curStat)
        if not itemIsAccessory then
            if self:TableContains(self.attrWithLocal, curStat) then
                curStat = curStat .. " (Local)"
            end
        end
            for j, w in pairs(v) do
                -- will get stat values from here
            end
        print(self:GetExplicitID(curStat))
        table.insert(attribuitIDs, {['id'] = self:GetExplicitID(curStat)})
    end
    local endpoint = dkjson.decode(self:GetTradeEndpoint(self:GetTemplate(itemType, attribuitIDs)))
    return self:GetTradeUrl(endpoint.id)
end

-- Replace the numbers with # to match the format of the incoming attribuites
-- removes any identifier for fractured,crafted ect
function TradeQueryCurItem:SanitizeStat(curStat)
    curStat = curStat:gsub("{.*}", "")
    curStat = curStat:gsub("([+][1-9][0-9][0-9])", "+#")
    curStat = curStat:gsub("([1-9][0-9][0-9])", "#")
    curStat = curStat:gsub("([+][1-9][0-9])", "+#")
    curStat = curStat:gsub("([1-9][0-9])", "#")
    curStat = curStat:gsub("([+][0-9])", "+#")
    curStat = curStat:gsub("([0-9])", "#")
    curStat = curStat:gsub("[+]([()][#][-][#][)])", "+#")
    curStat = curStat:gsub("([()][#][-][#][)])", "#")
    return curStat
end

-- get number of implicit mods on the item
function TradeQueryCurItem:GetNumOfImplicit()
    self.numOfImplicits = string.sub(self.curItem[self.implicitIndex],11,1)
end

-- get the id's of implicit modifier if decided to do this
function TradeQueryCurItem:GetImplicitID()

end

-- get the id's of explicit modifiers
function TradeQueryCurItem:GetExplicitID(mod)
    local tradeStats = self:FetchStats()
    tradeStats:gsub("\n", " ")
	local tradeQueryStatsParsed = dkjson.decode(tradeStats)
    for i=1, #tradeQueryStatsParsed.result[2]['entries'] do      
        if tradeQueryStatsParsed.result[2]['entries'][i]['text'] == mod then
            return tradeQueryStatsParsed.result[2]['entries'][i]['id']
        end
    end
    return nil
end

-- Return the first index with the given value (or nil if not found).
function TradeQueryCurItem:GetTableIndexEqual(haystack, needle)
    for i=1, #haystack do
        if haystack[i] == needle then
            return i
        end
    end
    return nil
end

-- return the first index that contains the given value nil if not found
function TradeQueryCurItem:GetTableIndexContains(haystack, needle)
    for i=1, #haystack do
        if string.find(haystack[i], needle) then
            return i
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

-- init mods from file
function TradeQueryCurItem:InitMods()
     local file = io.open(self.queryModsFilePath,"r")
    if file then
        file:close()
        self.modData = LoadModule(self.queryModsFilePath)
        return
    end
end

-- check if item is an accessory, need this to know if needing to use the Local option or not
function TradeQueryCurItem:CheckIfItemIsAccessory(item)
    local items = self:FetchItems()
    for i=1, #items.result[1].entries do
        if string.find(items.result[1].entries[i]['type'], item) then
            return true
        end
    end
    return false
end

-- hit the api to get the item attribuites
function TradeQueryCurItem:FetchStats()
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
	return tradeStats
end

-- hit the api to get a list of items, need this to determine if items are accessories or not
function TradeQueryCurItem:FetchItems()
	local items = ""
	local easy = common.curl.easy()
	easy:setopt_url("https://www.pathofexile.com/api/trade/data/items")
	easy:setopt_useragent("Path of Building/" .. launch.versionNumber .. "test")
	easy:setopt_writefunction(function(data)
		items = items..data
		return true
	end)
	easy:perform()
	easy:close()
	return dkjson.decode(items)

end

-- template for getting the url endpoint
function TradeQueryCurItem:GetTemplate(type, attribuiteIDs)
    local template = {
        ["query"] = {
          ["status"] = {
            ["option"] = "online"
          },
          ["type"] = type,
          ["stats"] = {
            {
              ["type"] = "and",
              ["filters"] = attribuiteIDs
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

-- passes the template to recieve the endpoint
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

function TradeQueryCurItem:GetFileCreatedTime(path)
    local cwd = io.popen("cd"):read()
    path = path:gsub('/', '\\')
    local cdate = io.popen( "dir /T:C \""..cwd..path.."\"", "r" )
    local createdate = cdate:read("*all")
    local pos = 0
    
    for i = 0, 4 do
       pos = string.find(createdate, "\n", pos+1)
    end
    
    createdate = string.sub(createdate, pos, pos+17)
    local year = string.sub(createdate, 8, 11)
    local month = string.sub(createdate, 5, 6)
    local day = string.sub(createdate, 2, 3)
    local hour = string.sub(createdate, 14, 15)
    local minute = string.sub(createdate, 17, 18)
    
    return month.."-"..day
end
