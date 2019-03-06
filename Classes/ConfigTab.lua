-- Path of Building
--
-- Module: Config Tab
-- Configuration tab for the current build.
--
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local gameVersionDropList = {
	{ label = "2.6 (Atlas of Worlds)", version = "2_6", versionPretty = "2.6" },
	{ label = "3.5 (War for the Atlas)", version = "3_0", versionPretty = "3.5" },
}

local varList = LoadModule("Modules/ConfigOptions")

local ConfigTabClass = newClass("ConfigTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.input = { }

	self.sectionList = { }
	self.varControls = { }
	
	self:BuildModList()

	local lastSection
	for _, varData in ipairs(varList) do
		if varData.section then
			lastSection = new("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, 0, 0, 360, 0, varData.section)
			lastSection.varControlList = { }
			lastSection.col = varData.col
			lastSection.height = function(self)
				local height = 20
				for _, varControl in pairs(self.varControlList) do
					if varControl:IsShown() then
						height = height + 20
					end
				end
				return m_max(height, 32)
			end
			t_insert(self.sectionList, lastSection)
			t_insert(self.controls, lastSection)
		elseif not varData.ifVer or varData.ifVer == build.targetVersion then
			local control
			if varData.type == "check" then
				control = new("CheckBoxControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 18, nil, function(state)
					self.input[varData.var] = state
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			elseif varData.type == "count" or varData.type == "integer" then
				control = new("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 90, 18, "", nil, varData.type == "integer" and "^%-%d" or "%D", 6, function(buf)
					self.input[varData.var] = tonumber(buf)
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			elseif varData.type == "list" then
				control = new("DropDownControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 118, 16, varData.list, function(index, value)
					self.input[varData.var] = value.val
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			else 
				control = new("Control", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 16, 16)
			end
			if varData.ifNode then
				control.shown = function()
					if self.build.spec.allocNodes[varData.ifNode] then
						return true
					end
					local node = self.build.spec.nodes[varData.ifNode]
					if node.type == "Keystone" then
						return self.build.calcsTab.mainEnv.keystonesAdded[node.dn]
					end
				end
				control.tooltipText = function()
					return "This option is specific to '"..self.build.spec.nodes[varData.ifNode].dn.."'."..(varData.tooltip and "\n"..varData.tooltip or "")
				end
			elseif varData.ifOption then
				control.shown = function()
					return self.input[varData.ifOption]
				end
			elseif varData.ifCond or varData.ifMinionCond or varData.ifEnemyCond then
				control.shown = function()
					local mainEnv = self.build.calcsTab.mainEnv
					if self.input[varData.var] then
						if (varData.implyCond and mainEnv.conditionsUsed[varData.implyCond]) or
						   (varData.implyMinionCond and mainEnv.minionConditionsUsed[varData.implyMinionCond]) or
						   (varData.implyEnemyCond and mainEnv.enemyConditionsUsed[varData.implyEnemyCond]) then
							return true
						end
					end
					if varData.ifCond then
						return mainEnv.conditionsUsed[varData.ifCond]
					elseif varData.ifMinionCond then
						return mainEnv.minionConditionsUsed[varData.ifMinionCond]
					else
						return mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
					end
				end
				control.tooltipText = function()
					if launch.devModeAlt then
						local out = varData.tooltip or ""
						local list
						if varData.ifCond then
							list = self.build.calcsTab.mainEnv.conditionsUsed[varData.ifCond]
						elseif varData.ifMinionCond then
							list = self.build.calcsTab.mainEnv.minionConditionsUsed[varData.ifMinionCond]
						else
							list = self.build.calcsTab.mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
						end
						for _, mod in ipairs(list) do
							out = (#out > 0 and out.."\n" or out) .. modLib.formatMod(mod) .. "|" .. mod.source
						end
						return out
					else
						return varData.tooltip
					end
				end
			elseif varData.ifMult or varData.ifEnemyMult then
				control.shown = function()
					local mainEnv = self.build.calcsTab.mainEnv
					if self.input[varData.var] then
						if (varData.implyCond and mainEnv.conditionsUsed[varData.implyCond]) or
						   (varData.implyMinionCond and mainEnv.minionConditionsUsed[varData.implyMinionCond]) or
						   (varData.implyEnemyCond and mainEnv.enemyConditionsUsed[varData.implyEnemyCond]) then
							return true
						end
					end
					if varData.ifMult then
						return mainEnv.multipliersUsed[varData.ifMult]
					else
						return mainEnv.enemyMultipliersUsed[varData.ifEnemyMult]
					end
				end
				control.tooltipText = function()
					if launch.devModeAlt then
						local out = varData.tooltip or ""
						for _, mod in ipairs(self.build.calcsTab.mainEnv.multipliersUsed[varData.ifMult]) do
							out = (#out > 0 and out.."\n" or out) .. modLib.formatMod(mod) .. "|" .. mod.source
						end
						return out
					else
						return varData.tooltip
					end
				end
			elseif varData.ifFlag then
				control.shown = function()
					return self.build.calcsTab.mainEnv.player.mainSkill.skillFlags[varData.ifFlag] -- O_O
				end
				control.tooltipText = varData.tooltip
			elseif varData.ifSkill or varData.ifSkillList then
				control.shown = function()
					if varData.ifSkillList then
						for _, skillName in ipairs(varData.ifSkillList) do
							if self.build.calcsTab.mainEnv.skillsUsed[skillName] then
								return true
							end
						end
					else
						return self.build.calcsTab.mainEnv.skillsUsed[varData.ifSkill]
					end
				end
				control.tooltipText = varData.tooltip
			else
				control.tooltipText = varData.tooltip
			end
			t_insert(self.controls, new("LabelControl", {"RIGHT",control,"LEFT"}, -4, 0, 0, DrawStringWidth(14, "VAR", varData.label) > 228 and 12 or 14, "^7"..varData.label))
			if varData.var then
				self.varControls[varData.var] = control
			end
			t_insert(self.controls, control)
			t_insert(lastSection.varControlList, control)
		end
	end

	-- Special control for game version selector
	self.controls.gameVersion = new("DropDownControl", {"TOPLEFT",self.sectionList[1],"TOPLEFT"}, 234, 0, 118, 16, gameVersionDropList, function(index, value)
		if value.version ~= build.targetVersion then
			main:OpenConfirmPopup("Convert Build", colorCodes.WARNING.."Warning:^7 Converting a build to a different game version may have side effects.\nFor example, if the passive tree has changed, then some passives may be deallocated.\nYou should create a backup copy of the build before proceeding.", "Convert to "..value.versionPretty, function()
				if build.unsaved then
					build:OpenSavePopup("VERSION", value.version)
				else
					if build.dbFileName then
						build.targetVersion = value.version
						build:SaveDBFile()
					end
					build:Shutdown()
					build:Init(build.dbFileName, build.buildName, nil, value.version)
				end
			end)
		end
	end)
	t_insert(self.controls, new("LabelControl", {"RIGHT",self.controls.gameVersion,"LEFT"}, -4, 0, 0, 14, "^7Game Version:"))
	t_insert(self.sectionList[1].varControlList, 1, self.controls.gameVersion)

	self.controls.scrollBar = new("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, 0, 0, 18, 0, 50, "VERTICAL", true)
end)

function ConfigTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "Input" then
			if not node.attrib.name then
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing name attribute", fileName)
				return true
			end
			if node.attrib.number then
				self.input[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				self.input[node.attrib.name] = node.attrib.string
			elseif node.attrib.boolean then
				self.input[node.attrib.name] = node.attrib.boolean == "true"
			else
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing number, string or boolean attribute", fileName)
				return true
			end
		end
	end
	self:BuildModList()
	self:UpdateControls()
	self:ResetUndo()
end

function ConfigTabClass:Save(xml)
	for k, v in pairs(self.input) do
		if v then
			local child = { elem = "Input", attrib = {name = k} }
			if type(v) == "number" then
				child.attrib.number = tostring(v)
			elseif type(v) == "boolean" then
				child.attrib.boolean = tostring(v)
			else
				child.attrib.string = tostring(v)
			end
			t_insert(xml, child)
		end
	end
	self.modFlag = false
end

function ConfigTabClass:UpdateControls()
	for var, control in pairs(self.varControls) do
		if control._className == "EditControl" then
			control:SetText(tostring(self.input[var] or ""))
		elseif control._className == "CheckBoxControl" then
			control.state = self.input[var]
		elseif control._className == "DropDownControl" then
			control:SelByValue(self.input[var], "val")
		end
	end
end

function ConfigTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	if not main.popups[1] then
		-- >_>
		self.controls.gameVersion:SelByValue(self.build.targetVersion, "version")
	end

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			end
		end
	end

	self:ProcessControlsInput(inputEvents, viewPort)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if event.key == "WHEELDOWN" then
				self.controls.scrollBar:Scroll(1)
			elseif event.key == "WHEELUP" then
				self.controls.scrollBar:Scroll(-1)
			end
		end
	end

	local maxCol = m_floor((viewPort.width - 10) / 370)
	local maxColY = 0
	local colY = { }
	for _, section in ipairs(self.sectionList) do
		local y = 14
		section.shown = true
		local doShow = false
		for _, varControl in ipairs(section.varControlList) do
			if varControl:IsShown() then
				doShow = true
				local width, height = varControl:GetSize()
				varControl.y = y + (18 - height) / 2
				y = y + 20
			end
		end
		section.shown = doShow
		if doShow then
			local width, height = section:GetSize()
			local col
			if section.col and (colY[section.col] or 0) + height + 28 <= viewPort.height then
				col = section.col
			else
				col = 1
				for c = 2, maxCol do
					colY[c] = colY[c] or 0
					if colY[c] < colY[col] then
						col = c
					end
				end
			end
			colY[col] = colY[col] or 0
			section.x = 10 + (col - 1) * 370
			section.y = colY[col] + 18
			colY[col] = colY[col] + height + 18
			maxColY = m_max(maxColY, colY[col])
		end
	end

	self.controls.scrollBar.height = viewPort.height
	self.controls.scrollBar:SetContentDimension(maxColY + 10, viewPort.height)
	for _, section in ipairs(self.sectionList) do
		section.y = section.y - self.controls.scrollBar.offset
	end

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ConfigTabClass:BuildModList()
	local modList = new("ModList")
	self.modList = modList
	local enemyModList = new("ModList")
	self.enemyModList = enemyModList
	local input = self.input
	for _, varData in ipairs(varList) do
		if varData.apply and (not varData.ifVer or varData.ifVer == self.build.targetVersion) then
			if varData.type == "check" then
				if input[varData.var] then
					varData.apply(true, modList, enemyModList, self.build)
				end
			elseif varData.type == "count" or varData.type == "integer" then
				if input[varData.var] and input[varData.var] ~= 0 then
					varData.apply(input[varData.var], modList, enemyModList, self.build)
				end
			elseif varData.type == "list" then
				if input[varData.var] then
					varData.apply(input[varData.var], modList, enemyModList, self.build)
				end
			end
		end
	end
end

function ConfigTabClass:ImportCalcSettings()
	local input = self.input
	local calcsInput = self.build.calcsTab.input
	local function import(old, new)
		input[new] = calcsInput[old]
		calcsInput[old] = nil
	end
	import("Cond_LowLife", "conditionLowLife")
	import("Cond_FullLife", "conditionFullLife")
	import("buff_power", "usePowerCharges")
	import("buff_frenzy", "useFrenzyCharges")
	import("buff_endurance", "useEnduranceCharges")
	import("CondBuff_Onslaught", "buffOnslaught")
	import("CondBuff_Phasing", "buffPhasing")
	import("CondBuff_Fortify", "buffFortify")
	import("CondBuff_UsingFlask", "conditionUsingFlask")
	import("buff_pendulum", "usePendulum")
	import("CondEff_EnemyCursed", "conditionEnemyCursed")
	import("CondEff_EnemyBleeding", "conditionEnemyBleeding")
	import("CondEff_EnemyPoisoned", "conditionEnemyPoisoned")
	import("CondEff_EnemyBurning", "conditionEnemyBurning")
	import("CondEff_EnemyIgnited", "conditionEnemyIgnited")
	import("CondEff_EnemyChilled", "conditionEnemyChilled")
	import("CondEff_EnemyFrozen", "conditionEnemyFrozen")
	import("CondEff_EnemyShocked", "conditionEnemyShocked")
	import("effective_physicalRed", "enemyPhysicalReduction")
	import("effective_fireResist", "enemyFireResist")
	import("effective_coldResist", "enemyColdResist")
	import("effective_lightningResist", "enemyLightningResist")
	import("effective_chaosResist", "enemyChaosResist")
	import("effective_enemyIsBoss", "enemyIsBoss")
	self:BuildModList()
	self:UpdateControls()
end

function ConfigTabClass:CreateUndoState()
	return copyTable(self.input)
end

function ConfigTabClass:RestoreUndoState(state)
	wipeTable(self.input)
	for k, v in pairs(state) do
		self.input[k] = v
	end
	self:UpdateControls()
	self:BuildModList()
end
