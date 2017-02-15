-- Path of Building
--
-- Class: Passive Spec List
-- Passive spec list control.
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local PassiveSpecListClass = common.NewClass("PassiveSpecList", "Control", "ControlHost", function(self, anchor, x, y, width, height, treeTab)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.treeTab = treeTab
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 16, 0, 32)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
	self.controls.copy = common.New("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, 2, -4, 60, 18, "Copy", function()
		local prevSel = self.selSpec
		self.selSpec = common.New("PassiveSpec", treeTab.build)
		self.selSpec.title = prevSel.title
		self.selSpec.jewels = copyTable(prevSel.jewels)
		self.selSpec:DecodeURL(prevSel:EncodeURL())
		self:RenameSel(true)
	end)
	self.controls.copy.enabled = function()
		return self.selSpec ~= nil
	end
	self.controls.delete = common.New("ButtonControl", {"LEFT",self.controls.copy,"RIGHT"}, 4, 0, 60, 18, "Delete", function()
		self:OnKeyUp("DELETE")
	end)
	self.controls.delete.enabled = function()
		return self.selSpec ~= nil and #treeTab.specList > 1
	end
	self.controls.rename = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOP"}, -2, -4, 60, 18, "Rename", function()
		self:RenameSel()
	end)
	self.controls.rename.enabled = function()
		return self.selSpec ~= nil
	end
	self.controls.new = common.New("ButtonControl", {"RIGHT",self.controls.rename,"LEFT"}, -4, 0, 60, 18, "New", function()
		self.selSpec = common.New("PassiveSpec", treeTab.build)
		self:RenameSel(true)
	end)
end)

function PassiveSpecListClass:SelectIndex(index)
	self.selSpec = self.treeTab.specList[index]
	if self.selSpec then
		self.selSpec = index
		self.controls.scrollBar:ScrollIntoView((index - 2) * 16, 48)
	end
end

function PassiveSpecListClass:RenameSel(addOnName)
	local popup
	popup = main:OpenPopup(370, 100, self.selSpec.title and "Rename" or "Set Name", {
		common.New("LabelControl", nil, 0, 20, 0, 16, "^7Enter name for this passive tree:"),
		edit = common.New("EditControl", nil, 0, 40, 350, 20, self.selSpec.title, nil, nil, 100, function(buf)
			popup.controls.save.enabled = buf:match("%S")
		end),
		save = common.New("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
			self.selSpec.title = popup.controls.edit.buf
			self.treeTab.modFlag = true
			if addOnName then
				t_insert(self.treeTab.specList, self.selSpec)
				self.selIndex = #self.treeTab.specList
			end
			main:ClosePopup()
		end),
		cancel = common.New("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
			if addOnName then
				self.selSpec = nil
			end
			main:ClosePopup()
		end),
	}, "save", "edit", "cancel")
	popup.controls.save.enabled = false
end

function PassiveSpecListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function PassiveSpecListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local list = self.treeTab.specList
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#list * 16, height - 4)
	self.selDragIndex = nil
	if self.selSpec and self.selDragging then
		local cursorX, cursorY = GetCursorPos()
		if not self.selDragActive and (cursorX-self.selCX)*(cursorX-self.selCX)+(cursorY-self.selCY)*(cursorY-self.selCY) > 100 then
			self.selDragActive = true
		end
		if self.selDragActive then
			if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
				local index = math.floor((cursorY - y - 2 + scrollBar.offset) / 16 + 0.5) + 1
				if index < self.selIndex or index > self.selIndex + 1 then
					self.selDragIndex = m_min(index, #list + 1)
				end
			end
		end
	end
	if self.hasFocus then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort)
	SetViewport(x + 2, y + 2, width - 20, height - 4)
	local ttSpec, ttY, ttWidth
	local minIndex = m_floor(scrollBar.offset / 16 + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / 16 + 1), #list)
	for index = minIndex, maxIndex do
		local spec = list[index]
		local lineY = 16 * (index - 1) - scrollBar.offset
		local used = spec:CountAllocNodes()
		local label = (spec.title or "Default") .. " (" .. (spec.curAscendClassName ~= "None" and spec.curAscendClassName or spec.curClassName) .. ", " .. used .. " points)"
		local nameWidth = DrawStringWidth(16, "VAR", label)
		if not scrollBar.dragging and not self.selDragActive then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < width - 17 and relY >= 0 and relY >= lineY and relY < height - 2 and relY < lineY + 16 then
				ttSpec = spec
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = lineY + y + 2
			end
		end
		if spec == ttSpec or spec == self.selSpec then
			if self.hasFocus then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, lineY, width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, lineY + 1, width - 20, 14)		
		end
		SetDrawColor(1, 1, 1)
		DrawString(0, lineY, "LEFT", 16, "VAR", label)
	end
	if self.selDragIndex then
		local lineY = 16 * (self.selDragIndex - 1) - scrollBar.offset
		SetDrawColor(1, 1, 1)
		DrawImage(nil, 0, lineY - 1, width - 20, 3)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, 0, lineY, width - 20, 1)
	end
	SetViewport()
end

function PassiveSpecListClass:OnKeyDown(key, doubleClick)
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
	if key == "LEFTBUTTON" then
		self.selSpec = nil
		self.selIndex = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + self.controls.scrollBar.offset) / 16) + 1
			local selSpec = self.treeTab.specList[index]
			if selSpec then
				self.selSpec = selSpec
				self.selIndex = index
			end
		end
		if self.selSpec then
			self.selCX = cursorX
			self.selCY = cursorY
			self.selDragging = true
			self.selDragActive = false
		end
	elseif #self.treeTab.specList > 0 then
		if key == "UP" then
			self:SelectIndex(((self.selIndex or 1) - 2) % #self.treeTab.specList + 1)
		elseif key == "DOWN" then
			self:SelectIndex((self.selIndex or #self.treeTab.specList) % #self.treeTab.specList + 1)
		elseif key == "HOME" then
			self:SelectIndex(1)
		elseif key == "END" then
			self:SelectIndex(#self.treeTab.specList)
		end
	end
	return self
end

function PassiveSpecListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	elseif self.selSpec then
		if key == "BACK" or key == "DELETE" then
			if #self.treeTab.specList > 1 then
				main:OpenConfirmPopup("Delete Spec", "Are you sure you want to delete '"..(self.selSpec.title or "Default").."'?", "Delete", function()
					t_remove(self.treeTab.specList, self.selIndex)
					self.selSpec = nil
					if self.selIndex == self.treeTab.activeSpec then 
						self.treeTab:SetActiveSpec(m_max(1, self.selIndex - 1))
					end
				end)
			end
		elseif key == "F2" then
			self:RenameSel()
		elseif key == "LEFTBUTTON" then
			self.selDragging = false
			if self.selDragActive then
				self.selDragActive = false
				if self.selDragIndex and self.selDragIndex ~= self.selIndex then
					local activeSpec = self.treeTab.specList[self.treeTab.activeSpec]
					t_remove(self.treeTab.specList, self.selIndex)
					if self.selDragIndex > self.selIndex then
						self.selDragIndex = self.selDragIndex - 1
					end
					t_insert(self.treeTab.specList, self.selDragIndex, self.selSpec)
					self.selSpec = nil
					self.treeTab.activeSpec = isValueInArray(self.treeTab.specList, activeSpec)
				end
			end
		end
	end
	return self
end