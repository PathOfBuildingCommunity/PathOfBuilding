-- Path of Building
--
-- Class: Text List
-- Simple list control for displaying a block of text
--
local launch, main = ...

local TextListClass = common.NewClass("TextListControl", "Control", "ControlHost", function(self, anchor, x, y, width, height, columns, list)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 18, 0, 40)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
	self.columns = columns or { { x = 0, align = "LEFT" } }
	self.list = list or { }
end)

function TextListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function TextListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local scrollBar = self.controls.scrollBar
	local contentHeight = 0
	for _, lineInfo in pairs(self.list) do
		contentHeight = contentHeight + lineInfo.height
	end
	scrollBar:SetContentDimension(contentHeight, height - 4)
	SetDrawColor(0.66, 0.66, 0.66)
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort)
	SetViewport(x + 2, y + 2, width - 20, height - 4)
	for colIndex, colInfo in pairs(self.columns) do
		local lineY = -scrollBar.offset
		for _, lineInfo in ipairs(self.list) do
			if lineInfo[colIndex] then
				DrawString(colInfo.x, lineY, colInfo.align, lineInfo.height, "VAR", lineInfo[colIndex])
			end
			lineY = lineY + lineInfo.height
		end
	end
	SetViewport()
end

function TextListClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
end

function TextListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	end
end