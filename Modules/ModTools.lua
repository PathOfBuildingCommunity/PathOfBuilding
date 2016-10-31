-- Path of Building
--
-- Module: Mod Tools
-- Various functions for dealing with modifier lists and databases.
--

local t_insert = table.insert
local m_floor = math.floor
local m_abs = math.abs
local band = bit.band
local bor = bit.bor

modLib = { }

local function createMod(modName, modType, modVal, ...)
	local flags = 0
	local keywordFlags = 0
	local tagStart = 1
	local source
	if select('#', ...) >= 1 and type(select(1, ...)) == "string" then
		source = select(1, ...)
		tagStart = 2
	end
	if select('#', ...) >= 2 and type(select(2, ...)) == "number" then
		flags = select(2, ...)
		tagStart = 3
	end
	if select('#', ...) >= 3 and type(select(3, ...)) == "number" then
		keywordFlags = select(3, ...)
		tagStart = 4
	end
	return {
		name = modName,
		type = modType,
		value = modVal,
		flags = flags,
		keywordFlags = keywordFlags,
		source = source,
		tagList = { select(tagStart, ...) }
	}
end
modLib.createMod = createMod

modLib.parseMod = LoadModule("Modules/ModParser")

local function formatFlags(flags, src)
	local flagNames = { }
	for name, val in pairs(src) do
		if band(flags, val) == val then
			t_insert(flagNames, name)
		end
	end
	table.sort(flagNames)
	local ret
	for i, name in ipairs(flagNames) do
		ret = (ret and ret.."," or "") .. name
	end
	return ret or "-"
end
modLib.formatFlags = formatFlags

local function formatTags(tagList)
	local ret
	for _, tag in ipairs(tagList) do
		local paramNames = { }
		local haveType
		for name, val in pairs(tag) do
			if name == "type" then
				haveType = true
			else
				t_insert(paramNames, name)
			end
		end
		table.sort(paramNames)
		if haveType then
			t_insert(paramNames, 1, "type")
		end
		local str = ""
		for i, paramName in ipairs(paramNames) do
			if i > 1 then
				str = str .. "/"
			end
			str = str .. string.format("%s=%s", paramName, tostring(tag[paramName]))
		end
		ret = (ret and ret.."," or "") .. str
	end
	return ret or "-"
end

local function formatValue(value)
	if type(value) ~= "table" then
		return tostring(value)
	end
	local paramNames = { }
	local haveType
	for name, val in pairs(value) do
		if name == "type" then
			haveType = true
		else
			t_insert(paramNames, name)
		end
	end
	table.sort(paramNames)
	if haveType then
		t_insert(paramNames, 1, "type")
	end
	local ret = ""
	for i, paramName in ipairs(paramNames) do
		if i > 1 then
			ret = ret .. "/"
		end
		ret = ret .. string.format("%s=%s", paramName, tostring(value[paramName]))
	end
	return "{"..ret.."}"
end

function modLib.formatMod(mod)
	return string.format("%s = %s|%s|%s|%s|%s", formatValue(mod.value), mod.name, mod.type, formatFlags(mod.flags, ModFlag), formatFlags(mod.keywordFlags, KeywordFlag), formatTags(mod.tagList))
end

local hack = { }

local ModListClass = common.NewClass("ModList", function(self)
	self.multipliers = { }
	self.conditions = { }
	self.stats = { }
end)

function ModListClass:AddMod(mod)
	t_insert(self, mod)
end

function ModListClass:AddList(modList)
	for i = 1, #modList do
		t_insert(self, modList[i])
	end
end

function ModListClass:CopyList(modList)
	for i = 1, #modList do
		self:AddMod(copyTable(modList[i]))
	end
end

function ModListClass:ScaleAddList(modList, scale)
	for i = 1, #modList do
		local scaledMod = copyTable(modList[i])
		if type(scaledMod.value) == "number" then
			scaledMod.value = (m_floor(scaledMod.value) == scaledMod.value) and m_floor(scaledMod.value * scale) or scaledMod.value * scale
		end
		self:AddMod(scaledMod)
	end
end

function ModListClass:NewMod(...)
	self:AddMod(createMod(...))
end

function ModListClass:Sum(type, cfg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
	local flags = cfg and cfg.flags or 0
	local keywordFlags = cfg and cfg.keywordFlags or 0
	local skillName = cfg and cfg.skillName
	local skillGem = cfg and cfg.skillGem
	local skillPart = cfg and cfg.skillPart
	local slotName = cfg and cfg.slotName
	local source = cfg and cfg.source
	local tabulate = cfg and cfg.tabulate
	local result
	local nullValue = 0
	if tabulate or type == "LIST" then
		result = { }
		nullValue = nil
	elseif type == "MORE" then
		result = 1
	elseif type == "FLAG" then
		result = false
		nullValue = false
	else
		result = 0
	end
	hack[1] = arg1
	if arg1 then
		hack[2] = arg2
		if arg2 then
			hack[3] = arg3
			if arg3 then
				hack[4] = arg4
				if arg4 then
					hack[5] = arg5
					if arg5 then
						hack[6] = arg6
						if arg6 then
							hack[7] = arg7
							if arg7 then
								hack[8] = arg8
							end
						end
					end
				end
			end
		end
	end
	for i = 1, #hack do --i = 1, select('#', ...) do
		local modName = hack[i]--select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == type and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match(source)) then
				local value = mod.value
				for _, tag in pairs(mod.tagList) do
					if tag.type == "Multiplier" then
						local mult = (self.multipliers[tag.var] or 0)
						if _G.type(value) == "table" then
							value = copyTable(value)
							value.value = value.value * mult
						else
							value = value * mult
						end
					elseif tag.type == "PerStat" then
						local mult = m_floor((self.stats[tag.stat] or 0) / tag.div + 0.0001) + (tag.base or 0)
						if _G.type(value) == "table" then
							value = copyTable(value)
							value.value = value.value * mult
						else
							value = value * mult
						end
					elseif tag.type == "Condition" then
						if not self.conditions[tag.var] then
							value = nullValue
						end
					elseif tag.type == "SocketedIn" then
						if tag.slotName ~= slotName or (tag.keyword and (not skillGem or not gemIsType(skillGem, tag.keyword))) then
							value = nullValue
						end
					elseif tag.type == "SkillName" then
						if tag.skillName ~= skillName then
							value = nullValue
						end
					elseif tag.type == "SkillPart" then
						if tag.skillPart ~= skillPart then
							value = nullValue
						end
					elseif tag.type == "SlotName" then
						if tag.slotName ~= slotName then
							value = nullValue
						end
					end
				end
				if tabulate or type == "LIST" then
					if value then
						t_insert(result, value)
					end
				elseif type == "MORE" then
					result = result * (1 + value / 100)
				elseif type == "FLAG" then
					result = result or value
				else
					result = result + value
				end
			end
		end
		hack[i] = nil
	end
	return result
end

function ModListClass:Print()
	for _, mod in ipairs(self) do
		ConPrintf("%s|%s", modLib.formatMod(mod), mod.source or "?")
	end
end

local ModDBClass = common.NewClass("ModDB", function(self)
	self.mods = { }
	self.multipliers = { }
	self.conditions = { }
	self.stats = { }
end)

function ModDBClass:AddMod(mod)
	local name = mod.name
	if not self.mods[name] then
		self.mods[name] = { }
	end
	t_insert(self.mods[name], mod)
end

function ModDBClass:AddList(modList)
	local mods = self.mods
	for i = 1, #modList do
		local mod = modList[i]
		local name = mod.name
		if not mods[name] then
			mods[name] = { }
		end
		t_insert(mods[name], mod)
	end
end

function ModDBClass:CopyList(modList)
	for i = 1, #modList do
		self:AddMod(copyTable(modList[i]))
	end
end

function ModDBClass:ScaleAddList(modList, scale)
	for i = 1, #modList do
		local scaledMod = copyTable(modList[i])
		if type(scaledMod.value) == "number" then
			scaledMod.value = (m_floor(scaledMod.value) == scaledMod.value) and m_floor(scaledMod.value * scale) or scaledMod.value * scale
		end
		self:AddMod(scaledMod)
	end
end

function ModDBClass:NewMod(...)
	self:AddMod(createMod(...))
end

function ModDBClass:Sum(type, cfg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
	local flags = cfg and cfg.flags or 0
	local keywordFlags = cfg and cfg.keywordFlags or 0
	local skillName = cfg and cfg.skillName
	local skillGem = cfg and cfg.skillGem
	local skillPart = cfg and cfg.skillPart
	local slotName = cfg and cfg.slotName
	local source = cfg and cfg.source
	local tabulate = cfg and cfg.tabulate
	local result
	local nullValue = 0
	if tabulate or type == "LIST" then
		result = { }
		nullValue = nil
	elseif type == "MORE" then
		result = 1
	elseif type == "FLAG" then
		result = false
		nullValue = false
	else
		result = 0
	end
	hack[1] = arg1
	if arg1 then
		hack[2] = arg2
		if arg2 then
			hack[3] = arg3
			if arg3 then
				hack[4] = arg4
				if arg4 then
					hack[5] = arg5
					if arg5 then
						hack[6] = arg6
						if arg6 then
							hack[7] = arg7
							if arg7 then
								hack[8] = arg8
							end
						end
					end
				end
			end
		end
	end
	for i = 1, #hack do --i = 1, select('#', ...) do
		local modName = hack[i]--select(i, ...)
		local modList = self.mods[modName]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if (not type or mod.type == type )and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					local value = mod.value
					for _, tag in pairs(mod.tagList) do
						if tag.type == "Multiplier" then
							local mult = (self.multipliers[tag.var] or 0)
							if _G.type(value) == "table" then
								value = copyTable(value)
								value.value = value.value * mult
							else
								value = value * mult
							end
						elseif tag.type == "PerStat" then
							local mult = m_floor((self.stats[tag.stat] or 0) / tag.div + 0.0001) + (tag.base or 0)
							if _G.type(value) == "table" then
								value = copyTable(value)
								value.value = value.value * mult
							else
								value = value * mult
							end
						elseif tag.type == "Condition" then
							if not self.conditions[tag.var] then
								value = nullValue
							end
						elseif tag.type == "SocketedIn" then
							if tag.slotName ~= slotName or (tag.keyword and (not skillGem or not gemIsType(skillGem, tag.keyword))) then
								value = nullValue
							end
						elseif tag.type == "SkillName" then
							if tag.skillName ~= skillName then
								value = nullValue
							end
						elseif tag.type == "SkillPart" then
							if tag.skillPart ~= skillPart then
								value = nullValue
							end
						elseif tag.type == "SlotName" then
							if tag.slotName ~= slotName then
								value = nullValue
							end
						end
					end
					if tabulate then
						if value and value ~= 0 then
							t_insert(result, { value = value, mod = mod })
						end
					elseif type == "MORE" then
						result = result * (1 + value / 100)
					elseif type == "FLAG" then
						result = result or value
					elseif type == "LIST" then
						if value then
							t_insert(result, value)
						end
					else
						result = result + value
					end
				end
			end
		end
		hack[i] = nil
	end
	return result
end

function ModDBClass:Print()
	ConPrintf("=== Modifiers ===")
	local modNames = { }
	for modName in pairs(self.mods) do
		t_insert(modNames, modName)
	end
	table.sort(modNames)
	for _, modName in ipairs(modNames) do
		ConPrintf("'%s' = {", modName)
		for _, mod in ipairs(self.mods[modName]) do
			ConPrintf("\t%s = %s|%s|%s|%s|%s", formatValue(mod.value), mod.type, formatFlags(mod.flags, ModFlag), formatFlags(mod.keywordFlags, KeywordFlag), formatTags(mod.tagList), mod.source or "?")
		end
		ConPrintf("},")
	end
	ConPrintf("=== Conditions ===")
	local nameList = { }
	for name, value in pairs(self.conditions) do
		if value then
			t_insert(nameList, name)
		end
	end
	table.sort(nameList)
	for i, name in ipairs(nameList) do
		ConPrintf(name)
	end
	ConPrintf("=== Multipliers ===")
	wipeTable(nameList)
	for name, value in pairs(self.multipliers) do
		if value > 0 then
			t_insert(nameList, name)
		end
	end
	table.sort(nameList)
	for i, name in ipairs(nameList) do
		ConPrintf("%s = %d", name, self.multipliers[name])
	end
end