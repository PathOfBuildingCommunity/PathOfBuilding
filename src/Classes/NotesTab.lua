-- Path of Building
--
-- Module: Notes Tab
-- Notes tab for the current build.
--
local t_insert = table.insert

local NotesTabClass = newClass("NotesTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build

	self.lastContent = ""

	local colorDesc = [[^7This field supports different colors.  Using the caret symbol (^) followed by a Hex code or a number will set the color.  Below are some common color codes PoB uses:
^7xC8C8C8: ^xC8C8C8Normal    ^7x8888FF: ^x8888FFMagic    ^7xFFFF77: ^xFFFF77Rare    ^7xAF6025: ^xAF6025Unique
^7xB97123: ^xB97123Fire     ^7x3F6DB3: ^x3F6DB3Cold    ^7xADAA47: ^xADAA47Lightning     ^7xD02090: ^xD02090Chaos
	]]
	self.controls.colorDoc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 200, 16, colorDesc)
	self.controls.edit = new("EditControl", {"TOPLEFT",self.controls.colorDoc,"TOPLEFT"}, 0, 48, 0, 0, "", nil, "^%C\t\n", nil, nil, 16)
	self.controls.edit.width = function()
		return self.width - 16
	end
	self.controls.edit.height = function()
		return self.height - 64
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
