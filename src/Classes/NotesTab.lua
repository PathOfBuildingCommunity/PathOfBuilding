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

	local function getColorString(color, string) return color:gsub("%^", "^7")..": "..color..string end
	local colorDesc = [[^7This field supports different colors.  Using the caret symbol (^) followed by a Hex code or a number (0-9) will set the color.
Below are some common color codes PoB uses:	]]
	self.controls.colorDoc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, colorDesc)
	self.controls.normal = new("LabelControl", {"TOPLEFT",self.controls.colorDoc,"TOPLEFT"}, 0, 32, 50, 16, getColorString(colorCodes.NORMAL, "NORMAL"))
	self.controls.magic = new("LabelControl", {"TOPLEFT",self.controls.normal,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.MAGIC, "MAGIC"))
	self.controls.rare = new("LabelControl", {"TOPLEFT",self.controls.magic,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.RARE, "RARE"))
	self.controls.unique = new("LabelControl", {"TOPLEFT",self.controls.rare,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.UNIQUE, "UNIQUE"))
	self.controls.fire = new("LabelControl", {"TOPLEFT",self.controls.normal,"TOPLEFT"}, 0, 16, 50, 16, getColorString(colorCodes.FIRE, "FIRE"))
	self.controls.cold = new("LabelControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.COLD, "COLD"))
	self.controls.lightning = new("LabelControl", {"TOPLEFT",self.controls.cold,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.LIGHTNING, "LIGHTNING"))
	self.controls.chaos = new("LabelControl", {"TOPLEFT",self.controls.lightning,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.CHAOS, "CHAOS"))
	self.controls.strength = new("LabelControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, 0, 16, 50, 16, getColorString(colorCodes.STRENGTH, "STRENGTH"))
	self.controls.dexterity = new("LabelControl", {"TOPLEFT",self.controls.strength,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.DEXTERITY, "DEXTERITY"))
	self.controls.intelligence = new("LabelControl", {"TOPLEFT",self.controls.dexterity,"TOPLEFT"}, 150, 0, 50, 16, getColorString(colorCodes.INTELLIGENCE, "INTELLIGENCE"))

	self.controls.edit = new("EditControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, 0, 48, 0, 0, "", nil, "^%C\t\n", nil, nil, 16)
	self.controls.edit.width = function()
		return self.width - 16
	end
	self.controls.edit.height = function()
		return self.height - 112
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
