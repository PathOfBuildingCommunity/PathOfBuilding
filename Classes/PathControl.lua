-- Path of Building
--
-- Class: Path Control
-- Path control.
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert

local PathClass = common.NewClass("PathControl", "Control", "ControlHost", "UndoHandler", function(self, anchor, x, y, width, height, basePath, subPath, onChange)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.UndoHandler()
	self.basePath = basePath
	self.baseName = basePath:match("([^/]+)/$") or "Base"
	self:SetSubPath(subPath or "")
	self:ResetUndo()
	self.onChange = onChange
end)

function PathClass:SetSubPath(subPath, noUndo)
	if subPath == self.subPath then
		return
	end
	self.subPath = subPath
	self.folderList = {
		{ label = self.baseName, path = "" },
	}
	for folder, endIndex in subPath:gmatch("([^/]+)()") do
		t_insert(self.folderList, { label = folder, path = subPath:sub(1, endIndex) })
	end
	local x = 2
	local i = 1
	for index, folder in ipairs(self.folderList) do
		local button = self.controls["folder"..i]
		if not button then
			button = common.New("ButtonControl", {"LEFT",self,"LEFT"}, 0, 0, 0, self.height - 4)
			self.controls["folder"..i] = button
		end
		button.shown = true
		button.x = x
		button.label = folder.label
		button.width = DrawStringWidth(self.height - 8, "VAR", folder.label) + 10
		button.onClick = function()
			self:SetSubPath(folder.path)
		end
		folder.button = button
		x = x + button.width + 12
		i = i + 1
	end
	while self.controls["folder"..i] do
		self.controls["folder"..i].shown = false
		i = i + 1
	end
	if self.onChange then
		self.onChange(subPath)
	end
	if not noUndo then
		self:AddUndoState()
	end
end

function PathClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function PathClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort)
	for index, folder in ipairs(self.folderList) do
		local buttonX, buttonY = folder.button:GetPos()
		local buttonW, buttonH = folder.button:GetSize()
		SetDrawColor(1, 1, 1)
		main:DrawArrow(buttonX + buttonW + 6, y + height/2, 8, "RIGHT")
		if self.otherDragSource and index < #self.folderList then
			SetDrawColor(0, 1, 0, 0.25)
			DrawImage(nil, buttonX, buttonY, buttonW, buttonH)
		end
	end
end

function PathClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
end

function PathClass:CreateUndoState()
	return self.subPath
end

function PathClass:RestoreUndoState(state)
	self:SetSubPath(state, true)
end

