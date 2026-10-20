-- Path of Building
--
-- Class: Popup Dialog
-- Popup Dialog Box with a configurable list of controls
--
local m_floor = math.floor

---@class PopupDialogAnchorState: AnchorState
---@field other? Control|ControlHost|string

---@class PopupDialogControl: Control
---@field anchor PopupDialogAnchorState
---@field Click fun(self: PopupDialogControl, ...)
---@field IsScrollDownKey fun(self: PopupDialogControl, key: string): boolean
---@field IsScrollUpKey fun(self: PopupDialogControl, key: string): boolean
---@field Scroll fun(self: PopupDialogControl, mult: number)

---@class PopupDialogControls: table<string, PopupDialogControl>
---@field scrollBar PopupDialogControl

---@class PopupDialog: ControlHost, Control
---@field controls PopupDialogControls
---@field title Prop<string>
---@field enterControl? string
---@field escapeControl? string
---@field scrollBarFunc? fun()
---@field resizeFunc? fun()
---@field PopupDialog fun(self: PopupDialog, width: number, height: number, title: Prop<string>, controls: PopupDialogControls, enterControl?: string, defaultControl?: string, escapeControl?: string, scrollBarFunc?: fun(), resizeFunc?: fun()): PopupDialog
---@field Draw fun(self: PopupDialog, viewPort: Viewport)
---@field ProcessInput fun(self: PopupDialog, inputEvents: InputEvent[], viewPort: Viewport)
---@type PopupDialog
local PopupDialogClass = newClass("PopupDialog", "ControlHost", "Control")

---@param width number
---@param height number
---@param title Prop<string>
---@param controls PopupDialogControls
---@param enterControl? string
---@param defaultControl? string
---@param escapeControl? string
---@param scrollBarFunc? fun()
---@param resizeFunc? fun()
---@return PopupDialog
function PopupDialogClass:PopupDialog(width, height, title, controls, enterControl, defaultControl,
									escapeControl, scrollBarFunc, resizeFunc)
	self:ControlHost()
	self:Control(nil, {0, 0, width, height})
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
	-- allow scrollbar functionality inside of popups
	self.scrollBarFunc = scrollBarFunc
	-- allow resizing of popup
	self.resizeFunc = resizeFunc
	return self
end

---@param viewPort Viewport
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
	if self.scrollBarFunc then
		self.scrollBarFunc()
	end
	if self.resizeFunc then
		self.resizeFunc()
	end
	-- Draw controls
	self:DrawControls(viewPort)
end

---@param inputEvents InputEvent[]
---@param viewPort Viewport
function PopupDialogClass:ProcessInput(inputEvents, viewPort)
	self:ProcessControlsInput(inputEvents, viewPort)
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
		elseif self.scrollBarFunc and event.type == "KeyUp" then
			if self.controls.scrollBar:IsScrollDownKey(event.key) then
				self.controls.scrollBar:Scroll(1)
			elseif self.controls.scrollBar:IsScrollUpKey(event.key) then
				self.controls.scrollBar:Scroll(-1)
			end
		end
	end
end