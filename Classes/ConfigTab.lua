-- Path of Building
--
-- Module: Config Tab
-- Configuration tab for the current build.
--
local launch, main = ...

local t_insert = table.insert
local m_max = math.max

local varList = {
	{ section = "General" },
	{ var = "enemyLevel", type = "number", label = "Enemy Level:", tooltip = "This overrides the default enemy level used to estimate your hit and evade chances.\nThe default level is your character level, capped at 84, which is the same value\nused in-game to calculate the stats on the character sheet." },
	{ var = "conditionLowLife", type = "check", label = "Are you always on Low Life?", tooltip = "You will automatically be considered to be on Low Life if you have at least 65% life reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "LowLife" }, "Config")
	end },
	{ var = "conditionFullLife", type = "check", label = "Are you always on Full Life?", tooltip = "You will automatically be considered to be on Full Life if you have Chaos Innoculation,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "FullLife" }, "Config")
	end },
	{ section = "When In Combat" },
	{ var = "usePowerCharges", type = "check", label = "Do you use Power Charges?" },
	{ var = "useFrenzyCharges", type = "check", label = "Do you use Frenzy Charges?" },
	{ var = "useEnduranceCharges", type = "check", label = "Do you use Endurance Charges?" },
	{ var = "buffOnslaught", type = "check", label = "Do you have Onslaught?", tooltip = "In addition to allowing any 'while you have Onslaught' modifiers to apply,\nthis will enable the Onslaught buff itself. (20% increased Attack/Cast/Movement Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Onslaught" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffUnholyMight", type = "check", label = "Do you have Unholy Might?", tooltip = "This will enable the Unholy Might buff. (Gain 30% of Physical Damage as Extra Chaos Damage)", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UnholyMight" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPhasing", type = "check", label = "Do you have Phasing?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Phasing" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffFortify", type = "check", label = "Do you have Fortify?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Fortify" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsingFlask", type = "check", label = "Do you have a Flask active?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UsingFlask" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPendulum", type = "check", label = "Is Pendulum of Destruction active?", ifNode = 57197, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "PendulumOfDestruction" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnConsecratedGround", type = "check", label = "Are you on Consecrated Ground?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "OnConsecratedGround" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitRecently", type = "check", label = "Have you Hit Recently?", tooltip = "You will automatically be considered to have Hit Recently if your main skill is self-cast,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "HitRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCritRecently", type = "check", label = "Have you Crit Recently?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "CritRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledRecently", type = "check", label = "Have you Killed Recently?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "KilledRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitRecently", type = "check", label = "Have you been Hit Recently?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "BeenHitRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ section = "For Effective DPS" },
	{ var = "conditionEnemyCursed", type = "check", label = "Is the enemy Cursed?", tooltip = "Your enemy will automatically be considered to be Cursed if you have at least one curse enabled,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyCursed" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBleeding", type = "check", label = "Is the enemy Bleeding?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyBleeding" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyPoisoned", type = "check", label = "Is the enemy Poisoned?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyPoisoned" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyMaimed", type = "check", label = "Is the enemy Maimed?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyMaimed" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBurning", type = "check", label = "Is the enemy Burning?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyBurning" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIgnited", type = "check", label = "Is the enemy Ignited?", tooltip = "This also implies that the enemy is Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyIgnited" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilled", type = "check", label = "Is the enemy Chilled?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyChilled" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFrozen", type = "check", label = "Is the enemy Frozen?", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyFrozen" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyShocked", type = "check", label = "Is the enemy Shocked?", tooltip = "In addition to allowing any 'against Shocked Enemies' modifiers to apply,\nthis will apply Shock's Damage Taken modifier to the enemy.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyShocked" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyIsBoss", type = "check", label = "Is the enemy a Boss?", tooltip = "This adds the following modifiers:\n60% less Effect of your Curses\n+30% to enemy Elemental Resistances\n+15% to enemy Chaos Resistance", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("CurseEffect", "MORE", -60, "Boss")
		enemyModList:NewMod("ElementalResist", "BASE", 30, "Boss")
		enemyModList:NewMod("ChaosResist", "BASE", 15, "Boss")
	end },
	{ var = "enemyPhysicalReduction", type = "number", label = "Enemy Phys. Damage Reduction:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("PhysicalDamageReduction", "INC", val, "Config")
	end },
	{ var = "enemyFireResist", type = "number", label = "Enemy Fire Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "BASE", val, "Config")
	end },
	{ var = "enemyColdResist", type = "number", label = "Enemy Cold Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "BASE", val, "Config")
	end },
	{ var = "enemyLightningResist", type = "number", label = "Enemy Lightning Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "BASE", val, "Config")
	end },
	{ var = "enemyChaosResist", type = "number", label = "Enemy Chaos Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ChaosResist", "BASE", val, "Config")
	end },
}

local ConfigTabClass = common.NewClass("ConfigTab", "UndoHandler", "ControlHost", "Control", function(self, build)
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
			if lastSection then
				lastSection = common.New("SectionControl", {"TOPLEFT",lastSection,"BOTTOMLEFT"}, 0, 18, 300, 0, varData.section)
			else
				lastSection = common.New("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, 10, 18, 300, 0, varData.section)
			end
			lastSection.varControlList = { }
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
		else
			local control
			if varData.type == "check" then
				control = common.New("CheckBoxControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 216, 0, 18, nil, function(state)
					self.input[varData.var] = state
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			elseif varData.type == "number" then
				control = common.New("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 216, 0, 50, 18, "", nil, "^%-%d", 4, function(buf)
					self.input[varData.var] = tonumber(buf)
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			end
			control.tooltip = varData.tooltip
			if varData.ifNode then
				control.shown = function()
					return self.build.spec.allocNodes[varData.ifNode]
				end
			end
			t_insert(self.controls, common.New("LabelControl", {"RIGHT",control,"LEFT"}, -4, 2, 0, 14, "^7"..varData.label))
			self.varControls[varData.var] = control
			t_insert(self.controls, control)
			t_insert(lastSection.varControlList, control)
		end
	end
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
	self.modFlag = false
end

function ConfigTabClass:UpdateControls()
	for var, control in pairs(self.varControls) do
		if control._className == "EditControl" then
			control:SetText(tostring(self.input[var] or ""))
		elseif control._className == "CheckBoxControl" then
			control.state = self.input[var]
		end
	end
end

function ConfigTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

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

	for _, section in ipairs(self.sectionList) do
		local y = 14
		for _, varControl in ipairs(section.varControlList) do
			if varControl:IsShown() then
				varControl.y = y
				y = y + 20
			end
		end
	end

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ConfigTabClass:BuildModList()
	local modList = common.New("ModList")
	self.modList = modList
	local enemyModList = common.New("ModList")
	self.enemyModList = enemyModList
	local input = self.input
	for _, varData in ipairs(varList) do
		if varData.apply then
			if varData.type == "check" then
				if input[varData.var] then
					varData.apply(true, modList, enemyModList)
				end
			elseif varData.type == "number" then
				if input[varData.var] and input[varData.var] ~= 0 then
					varData.apply(input[varData.var], modList, enemyModList)
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
