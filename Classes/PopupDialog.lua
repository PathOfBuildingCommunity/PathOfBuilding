-- Path of Building
--
-- Class: Popup Dialog
-- Popup Dialog Box with a configurable list of controls
--
local launch, main = ...

local m_floor = math.floor

local PopupDialogClass = common.NewClass("PopupDialog", "ControlHost", "Control", function(self, width, height, title, controls, enterControl, defaultControl, escapeControl)
	self.ControlHost()
	self.Control(nil, 0, 0, width, height)
	self.x = function()
		return m_floor((main.screenW - width) / 2)
	end
	self.y = function()
		return m_floor((main.screenH - height) / 2)
	end
	self.title = title
	self.controls = controls
	self.enterControl = enterControl
	self.escapeControl = escapeControl
	for id, control in pairs(self.controls) do
		if not control.anchor.point then
			control:SetAnchor("TOP", self, "TOP")
		elseif not control.anchor.other then
			control.anchor.other = self
		elseif type(control.anchor.other) ~= "table" then
			control.anchor.other = self.controls[control.anchor.other]
		end
	end
	if defaultControl then
		self:SelectControl(self.controls[defaultControl])
	end
end)

function PopupDialogClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	-- Draw dialog background
	SetDrawColor(0.8, 0.8, 0.8)
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, x + 2, y + 2, width - 4, height - 4)
	-- Draw dialog title box
	local title = self:GetProperty("title")
	local titleWidth = DrawStringWidth(16, "VAR", title)
	local titleX = x + m_floor((width - titleWidth - 8) / 2)
	SetDrawColor(1, 1, 1)
	DrawImage(nil, titleX, y - 10, titleWidth + 8, 24)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, titleX + 2, y - 8, titleWidth + 4, 20)
	SetDrawColor(1, 1, 1)
	DrawString(titleX + 4, y - 7, "LEFT", 16, "VAR", title)
	-- Draw controls
	self:DrawControls(viewPort)
end

function PopupDialogClass:ProcessInput(inputEvents, viewPort)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "ESCAPE" then
				if self.escapeControl then
					self.controls[self.escapeControl]:Click()
				else
					main:ClosePopup()
				end
				return
			elseif event.key == "RETURN" then
				if self.enterControl then
					self.controls[self.enterControl]:Click()
					return
				end
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)
end