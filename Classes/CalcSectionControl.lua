-- Path of Building
--
-- Class: Calc Section Control
-- Section control used in the Calcs tab
--
local launch, main = ...

local t_insert = table.insert

local CalcSectionClass = common.NewClass("CalcSection", "Control", "ControlHost", function(self, calcsTab, width, id, group, label, col, data, updateFunc)
	self.Control(calcsTab, 0, 0, width, 0)
	self.ControlHost()
	self.calcsTab = calcsTab
	self.id = id
	self.group = group
	self.label = label
	self.col = col
	self.data = data
	self.extra = data.extra
	self.flag = data.flag
	self.notFlag = data.notFlag
	self.updateFunc = updateFunc
	for _, data in ipairs(self.data) do
		for _, colData in ipairs(data) do
			if colData.control then
				-- Add control to the section's control list and set show/hide function
				self.controls[colData.controlName] = colData.control
				colData.control.shown = function()
					return self.enabled and not self.collapsed and data.enabled
				end
			end
		end
	end
	self.controls.toggle = common.New("ButtonControl", {"TOPRIGHT",self,"TOPRIGHT"}, -3, 3, 16, 16, function()
		return self.collapsed and "+" or "-"
	end, function()
		self.collapsed = not self.collapsed
		self.calcsTab.modFlag = true
	end)
	self.controls.toggle.shown = function()
		return self.enabled
	end
	self.shown = function()
		return self.enabled
	end
end)

function CalcSectionClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	if self:GetMouseOverControl() then
		return true
	end
	local mOver = self:IsMouseInBounds()
	if mOver and not self.collapsed and self.enabled then
		-- Check if mouse is over one of the cells
		local cursorX, cursorY = GetCursorPos()
		for _, data in ipairs(self.data) do
			if data.enabled then
				for _, colData in ipairs(data) do
					if colData.control then
						if colData.control:IsMouseOver() then
							return mOver, colData
						end
					elseif cursorX >= colData.x and cursorY >= colData.y and cursorX < colData.x + colData.width and cursorY < colData.y + colData.height then
						return mOver, colData
					end
				end
			end
		end
	end
	return mOver
end

function CalcSectionClass:UpdateSize()
	self.enabled = self.calcsTab:CheckFlag(self)
	if not self.enabled then
		self.height = 22
		return
	end
	local x, y = self:GetPos()
	local width = self:GetSize()
	self.height = 0
	self.enabled = false
	local yOffset = 22
	for _, rowData in ipairs(self.data) do
		rowData.enabled = self.calcsTab:CheckFlag(rowData)
		if rowData.enabled then
			self.enabled = true
			local xOffset = 134
			for col, colData in ipairs(rowData) do
				colData.xOffset = xOffset
				colData.yOffset = yOffset
				colData.width = self.data.colWidth or width - 136
				colData.height = 18
				xOffset = xOffset + colData.width
			end
			yOffset = yOffset + 18
			self.height = self.height + 18
		end
		if self.collapsed then
			rowData.enabled = false
		end
	end
	if self.enabled and not self.collapsed then
		self.height = self.height + 24
		if self.updateFunc then
			self:updateFunc()
		end
	else
		self.height = 22
	end
end

function CalcSectionClass:UpdatePos()
	if self.collapsed or not self.enabled then
		return
	end
	local x, y = self:GetPos()
	for _, rowData in ipairs(self.data) do
		if rowData.enabled then
			for col, colData in ipairs(rowData) do
				-- Update the real coordinates of this cell
				colData.x = x + colData.xOffset
				colData.y = y + colData.yOffset
				if colData.control then
					colData.control.x = colData.x + 4
					colData.control.y = colData.y + 9 - colData.control.height/2
				end
			end
		end
	end
end

function CalcSectionClass:FormatStr(str, actor, colData)
	str = str:gsub("{output:([%a%.:]+)}", function(c) 
		local ns, var = c:match("^(%a+)%.(%a+)$")
		if ns then
			return actor.output[ns] and actor.output[ns][var] or ""
		else
			return actor.output[c] or ""
		end
	end)
	str = str:gsub("{(%d+):output:([%a%.:]+)}", function(p, c) 
		local ns, var = c:match("^(%a+)%.(%a+)$")
		if ns then
			return formatRound(actor.output[ns] and actor.output[ns][var] or 0, tonumber(p))
		else
			return formatRound(actor.output[c] or 0, tonumber(p))
		end
	end)
	str = str:gsub("{(%d+):mod:(%d+)}", function(p, n) 
		local sectionData = colData[tonumber(n)]
		local modCfg = (sectionData.cfg and actor.mainSkill[sectionData.cfg.."Cfg"]) or { }
		if sectionData.modSource then
			modCfg.source = sectionData.modSource
		end
		local modVal
		if type(sectionData.modName) == "table" then
			modVal = actor.modDB:Sum(sectionData.modType, modCfg, unpack(sectionData.modName))
		else
			modVal = actor.modDB:Sum(sectionData.modType, modCfg, sectionData.modName)
		end
		if sectionData.modType == "MORE" then
			modVal = (modVal - 1) * 100
		end
		return formatRound(modVal, tonumber(p)) 
	end)
	return str
end

function CalcSectionClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local actor = self.calcsTab.input.showMinion and self.calcsTab.calcsEnv.minion or self.calcsTab.calcsEnv.player
	-- Draw border and background
	SetDrawLayer(nil, -10)
	SetDrawColor(self.col)
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0.10, 0.10, 0.10)
	DrawImage(nil, x + 2, y + 2, width - 4, height - 4)
	-- Draw label
	if not self.enabled then
		DrawString(x + 3, y + 3, "LEFT", 16, "VAR BOLD", "^8"..self.label)
	else
		DrawString(x + 3, y + 3, "LEFT", 16, "VAR BOLD", "^7"..self.label..":")
		if self.extra then
			local x = x + 3 + DrawStringWidth(16, "VAR BOLD", self.label) + 10
			DrawString(x, y + 3, "LEFT", 16, "VAR", self:FormatStr(self.extra, actor))
		end
	end
	-- Draw line below label
	SetDrawColor(self.col)
	DrawImage(nil, x + 2, y + 20, width - 4, 2)
	-- Draw controls
	SetDrawLayer(nil, 0)
	self:DrawControls(viewPort)
	if self.collapsed or not self.enabled then
		return
	end
	local lineY = y + 22
	for _, rowData in ipairs(self.data) do
		if rowData.enabled then
			if rowData.label then
				-- Draw row label with background
				SetDrawColor(rowData.bgCol or "^0")
				DrawImage(nil, x + 2, lineY, 130, 18)
				DrawString(x + 132, lineY + 1, "RIGHT_X", 16, "VAR", "^7"..rowData.label.."^7:")
			end
			for col, colData in ipairs(rowData) do
				-- Draw column separator at the left end of the cell
				SetDrawColor(self.col)
				DrawImage(nil, colData.x, lineY, 2, colData.height)
				if colData.format and self.calcsTab:CheckFlag(colData) then
					if cursorY >= viewPort.y and cursorY < viewPort.y + viewPort.height and cursorX >= colData.x and cursorY >= colData.y and cursorX < colData.x + colData.width and cursorY < colData.y + colData.height then
						self.calcsTab:SetDisplayStat(colData)
					end
					if self.calcsTab.displayData == colData then
						-- This is the display stat, draw a green border around this cell
						SetDrawColor(0.25, 1, 0.25)
						DrawImage(nil, colData.x + 2, colData.y, colData.width - 2, colData.height)
						SetDrawColor(rowData.bgCol or "^0")
						DrawImage(nil, colData.x + 3, colData.y + 1, colData.width - 4, colData.height - 2)
					else
						SetDrawColor(rowData.bgCol or "^0")
						DrawImage(nil, colData.x + 2, colData.y, colData.width - 2, colData.height)
					end
					local textSize = rowData.textSize or 14
					SetViewport(colData.x + 3, colData.y, colData.width - 4, colData.height)
					DrawString(1, 9 - textSize/2, "LEFT", textSize, "VAR", "^7"..self:FormatStr(colData.format, actor, colData))
					SetViewport()
				end
			end
			lineY = lineY + 18
		end
	end
end

function CalcSectionClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
	local mOver, mOverComp = self:IsMouseOver()
	if key:match("BUTTON") then
		if not mOver then
			return
		end
		if mOverComp then
			-- Pin the stat breakdown
			self.calcsTab:SetDisplayStat(mOverComp, true)
			return self.calcsTab.controls.breakdown
		end
	end
	return
end

function CalcSectionClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyUp then
		return mOverControl:OnKeyUp(key)
	end
	return
end