-- Path of Building
--
-- Module: Notes Tab
-- Notes tab for the current build.
--
local launch, main = ...

local t_insert = table.insert

local NotesTabClass = common.NewClass("NotesTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build

	self.lastContent = ""

	self.controls.edit = common.New("EditControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 0, 0, "", nil, "^%C\t\n", nil, nil, 16)
	self.controls.edit.width = function()
		return self.width - 16
	end
	self.controls.edit.height = function()
		return self.height - 16
	end
	self:SelectControl(self.controls.edit)
end)

function NotesTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if type(node) == "string" then
			self.controls.edit:SetText(node)
		end
	end
	self.lastContent = self.controls.edit.buf
end

function NotesTabClass:Save(xml)
	t_insert(xml, self.controls.edit.buf)
	self.lastContent = self.controls.edit.buf
end

function NotesTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "z" and IsKeyDown("CTRL") then
				self.controls.edit:Undo()
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.controls.edit:Redo()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	self.modFlag = (self.lastContent ~= self.controls.edit.buf)
end
