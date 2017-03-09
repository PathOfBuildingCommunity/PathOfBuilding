-- Path of Building
--
-- Class: Build List
-- Build list control.
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local BuildListClass = common.NewClass("BuildList", "Control", "ControlHost", function(self, anchor, x, y, width, height, listMode)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.listMode = listMode
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 18, 0, 40)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
	self.controls.scrollBar.locked = function()
		return self.listMode.edit
	end
	self.controls.nameEdit = common.New("EditControl", {"TOPLEFT",self,"TOPLEFT"}, 0, 0, 0, 20, nil, nil, "\\/:%*%?\"<>|%c", 50)
	self.controls.nameEdit.shown = function()
		return self.listMode.edit
	end
	self.controls.nameEdit.width = function()
		local width, height = self:GetSize()
		return width - 20
	end
end)

function BuildListClass:ScrollSelIntoView()
	if self.listMode.sel then
		local width, height = self:GetSize()
		self.controls.scrollBar:SetContentDimension(#self.listMode.list * 20, height - 4)
		self.controls.scrollBar:ScrollIntoView((self.listMode.sel - 2) * 20, 60)
	end
end

function BuildListClass:SelectIndex(index)
	if self.listMode.list[index] then
		self.listMode.sel = index
		self:ScrollSelIntoView()
	end
end

function BuildListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function BuildListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local list = self.listMode.list
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#list * 20, height - 4)
	if self.hasFocus then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	SetViewport(x + 2, y + 2, width - 22, height - 4)
	local selBuildIndex = self.listMode.sel
	local minIndex = m_floor(scrollBar.offset / 20 + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / 20 + 1), #list)
	for index = minIndex, maxIndex do
		local build = list[index]
		local lineY = 20 * (index - 1) - scrollBar.offset
		if index == selBuildIndex then
			self.controls.nameEdit.y = lineY + 2
		end
		local mOverLine
		if not scrollBar.dragging then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < width - 19 and relY >= 0 and relY >= lineY and relY < height - 2 and relY < lineY + 20 then
				mOverLine = true
			end
		end
		if index == selBuildIndex then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		DrawImage(nil, 0, lineY, width - 22, 20)
		if mOverLine or index == selBuildIndex then
			SetDrawColor(0.33, 0.33, 0.33)
		elseif index % 2 == 0 then
			SetDrawColor(0.05, 0.05, 0.05)
		else
			SetDrawColor(0, 0, 0)
		end
		DrawImage(nil, 0, lineY + 1, width - 22, 18)
		if self.listMode.edit ~= index then
			DrawString(0, lineY + 2, "LEFT", 16, "VAR", "^7"..(build.buildName or "?"))
			SetDrawColor(build.className and data.colorCodes[build.className:upper()] or "^7")
			DrawString(width - 160, lineY + 2, "LEFT", 16, "VAR", string.format("Level %d %s", build.level or 1, (build.ascendClassName ~= "None" and build.ascendClassName) or build.className or "?"))
		end
	end
	SetViewport()
	if self.listMode.edit then
		self.listMode:SelectControl(self.controls.nameEdit)
	end
	self:DrawControls(viewPort)
end

function BuildListClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
	if not self:IsMouseOver() and key:match("BUTTON") then
		return
	end
	if self.listMode.edit then
		return self
	end
	if key == "LEFTBUTTON" then
		self.listMode.sel = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 20 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + self.controls.scrollBar.offset) / 20) + 1
			local selBuild = self.listMode.list[index]
			if selBuild then
				self.listMode.sel = index
				if doubleClick then
					self.listMode:LoadSel()
				end
			end
		end
	elseif key == "UP" then
		self:SelectIndex(((self.listMode.sel or 1) - 2) % #self.listMode.list + 1)
	elseif key == "DOWN" then
		self:SelectIndex((self.listMode.sel or #self.listMode.list) % #self.listMode.list + 1)
	elseif key == "HOME" then
		self:SelectIndex(1)
	elseif key == "END" then
		self:SelectIndex(#self.listMode.list)
	elseif self.listMode.sel then
		if key == "BACK" or key == "DELETE" then
			self.listMode:DeleteSel()
		elseif key == "F2" then
			self.listMode:RenameSel()
		elseif key == "RETURN" then
			self.listMode:LoadSel()
		end
	end
	return self
end

function BuildListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	end
	return self
end