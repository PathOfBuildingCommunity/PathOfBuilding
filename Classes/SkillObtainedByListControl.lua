-- Path of Building
--
-- Class: Skill Obtained By List
-- Skill obtained by list control.
-- This list will show what level the gem can be obtained at
-- Future: 
--		What vendor the gem can be obtained at
--		Sort the list by gem level
--		Filter the gems by class
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local SkillObtainedListClass = newClass("SkillObtainedByListControl", "ListControl", function(self, anchor, x, y, width, height, skillsTab)
	self.ListControl(anchor, x, y, width, height, 16, false, true, self.list)
end)

function SkillObtainedListClass:GetRowValue(column, index, gemInstance)


	if gemInstance.gemData or gemInstance.grantedEffect then
		gemInstance.new = nil
		local grantedEffect = gemInstance.grantedEffect or gemInstance.gemData.grantedEffect
		if grantedEffect.color == 1 then
			gemInstance.color = colorCodes.STRENGTH
		elseif grantedEffect.color == 2 then
			gemInstance.color = colorCodes.DEXTERITY
		elseif grantedEffect.color == 3 then
			gemInstance.color = colorCodes.INTELLIGENCE
		else
			gemInstance.color = colorCodes.NORMAL
		end
		if prevDefaultLevel and gemInstance.gemData and gemInstance.gemData.defaultLevel ~= prevDefaultLevel then
			gemInstance.level = m_min(self.defaultGemLevel or gemInstance.gemData.defaultLevel, gemInstance.gemData.defaultLevel + 1)
			gemInstance.defaultLevel = gemInstance.level
		end
		calcLib.validateGemLevel(gemInstance)
		if gemInstance.gemData then
			self.reqLevel1 = grantedEffect.levels[1].levelRequirement
			
		end
	end

	if column == 1 then
		local label = gemInstance.nameSpec or "?"
		--if not gemInstance.enabled or not gemInstance.slotEnabled then
		if self.reqLevel1 == nil then 
			--label = gemInstance.color .. "" .. label
		else
			-- to be added when data for act/vendor reward is collected
			-- label = gemInstance.color .. "("  .. self.reqLevel1 ..  ") ".. label .. " [Act ##" .. " Vendor/Reward]\t"
			label = gemInstance.color .. "("  .. self.reqLevel1 ..  ") ".. label
		end
		return label
	end
end

function SkillObtainedListClass:UpdateAllGems(skillsTab)
	self.list = {}
	local sortedList = {}

	for _, socketGroup in ipairs (skillsTab.socketGroupList) do
		for _, gemInstance in ipairs(socketGroup.gemList) do
			local table = {}
			if gemInstance.gemData or gemInstance.grantedEffect then
				gemInstance.new = nil
				local grantedEffect = gemInstance.grantedEffect or gemInstance.gemData.grantedEffect
				sortedList[gemInstance] = grantedEffect.levels[1].levelRequirement
			end
		end
	end

	function compare(a,b)
		return a[1] < b[1]
	end

	table.sort(sortedList, compare)

	for key, value in next, sortedList do
		t_insert(self.list,  key)
	end

end
