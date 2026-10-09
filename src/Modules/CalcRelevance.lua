-- Path of Building
-- Conservative, per-execution evidence for add-node calculation pruning.
local calcs = require("Modules.CalcBase")
local band = bit.band

---@class CalcQueryObserver
---@field active boolean
---@field recorded boolean?
---@field unsafe string?
---@field queries table
---@field nodes table
local observer = { }
observer.__index = observer

function calcs.newQueryObserver()
	return setmetatable({ active = true, queries = { }, nodes = { } }, observer)
end

function observer:Query(modType, flags, keywordFlags, source, ...)
	if not self.active then
		return
	end
	for i = 1, select("#", ...) do
		local name = select(i, ...)
		if name then
			local signatures = self.queries[name]
			if not signatures then
				signatures = { }
				self.queries[name] = signatures
			end
			local key = (modType or "*") .. ":" .. flags .. ":" .. keywordFlags
			signatures[key] = { type = modType, flags = flags, keywordFlags = keywordFlags }
		end
	end
end

function observer:ObserveNodes(nodes)
	-- This closure belongs to one calculation-local table, never to the live spec.
	setmetatable(nodes, { __index = function(_, id)
		if self.active and id ~= nil then
			self.nodes[id] = true
		end
	end })
end

function observer:Seal()
	self.active = false
end

local function matchesQuery(queries, mod)
	for _, query in pairs(queries[mod.name] or { }) do
		if (not query.type or query.type == mod.type) and band(query.flags, mod.flags) == mod.flags and MatchKeywordFlags(query.keywordFlags, mod.keywordFlags) then
			return true
		end
	end
	return false
end

local relevance = { }
relevance.__index = relevance

function calcs.newNodeRelevance(env, observation, output)
	return setmetatable({
		env = env, observation = observation, output = output, memo = { },
		enabled = not observation.active and observation.recorded and not observation.unsafe,
	}, relevance)
end

function relevance:IsIrrelevant(node)
	if not self.enabled or type(node) ~= "table" then
		return false
	end
	if self.memo[node] ~= nil then
		return self.memo[node]
	end
	if self.observation.nodes[node.id] then
		self.memo[node] = false
		return false
	end
	local mods, grantsSkill, explodes = calcs.probeNodeContribution(self.env, node)
	if not mods or grantsSkill or explodes then
		return false
	end
	for _, mod in ipairs(mods) do
		if matchesQuery(self.observation.queries, mod) then
			self.memo[node] = false
			return false
		end
	end
	self.memo[node] = true
	return true
end

function relevance:CanSkip(override)
	if not self.enabled or not override.addNodes or not next(override.addNodes) or override.removeNodes then
		return false
	end
	for key in pairs(override) do
		if key ~= "addNodes" then
			return false
		end
	end
	for node in pairs(override.addNodes) do
		if not self:IsIrrelevant(node) then
			return false
		end
	end
	return true
end

return calcs
