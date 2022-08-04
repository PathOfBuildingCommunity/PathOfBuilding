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
	self.showColorCodes = false

	local notesDesc = [[^7You can use Ctrl +/- (or Ctrl+Scroll) to zoom in and out and Ctrl+0 to reset.
This field also supports different colors.  Using the caret symbol (^) followed by a Hex code or a number (0-9) will set the color.
Below are some common color codes PoB uses:	]]
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)
	self.controls.normal = new("ButtonControl", {"TOPLEFT",self.controls.notesDesc,"TOPLEFT"}, 0, 48, 100, 18, colorCodes.NORMAL.."NORMAL", function() self:SetColor(colorCodes.NORMAL) end)
	self.controls.magic = new("ButtonControl", {"TOPLEFT",self.controls.normal,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.MAGIC.."MAGIC", function() self:SetColor(colorCodes.MAGIC) end)
	self.controls.rare = new("ButtonControl", {"TOPLEFT",self.controls.magic,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.RARE.."RARE", function() self:SetColor(colorCodes.RARE) end)
	self.controls.unique = new("ButtonControl", {"TOPLEFT",self.controls.rare,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.UNIQUE.."UNIQUE", function() self:SetColor(colorCodes.UNIQUE) end)
	self.controls.fire = new("ButtonControl", {"TOPLEFT",self.controls.normal,"TOPLEFT"}, 0, 18, 100, 18, colorCodes.FIRE.."FIRE", function() self:SetColor(colorCodes.FIRE) end)
	self.controls.cold = new("ButtonControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.COLD.."COLD", function() self:SetColor(colorCodes.COLD) end)
	self.controls.lightning = new("ButtonControl", {"TOPLEFT",self.controls.cold,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.LIGHTNING.."LIGHTNING", function() self:SetColor(colorCodes.LIGHTNING) end)
	self.controls.chaos = new("ButtonControl", {"TOPLEFT",self.controls.lightning,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.CHAOS.."CHAOS", function() self:SetColor(colorCodes.CHAOS) end)
	self.controls.strength = new("ButtonControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, 0, 18, 100, 18, colorCodes.STRENGTH.."STRENGTH", function() self:SetColor(colorCodes.STRENGTH) end)
	self.controls.dexterity = new("ButtonControl", {"TOPLEFT",self.controls.strength,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.DEXTERITY.."DEXTERITY", function() self:SetColor(colorCodes.DEXTERITY) end)
	self.controls.intelligence = new("ButtonControl", {"TOPLEFT",self.controls.dexterity,"TOPLEFT"}, 120, 0, 100, 18, colorCodes.INTELLIGENCE.."INTELLIGENCE", function() self:SetColor(colorCodes.INTELLIGENCE) end)
	self.controls.default = new("ButtonControl", {"TOPLEFT",self.controls.intelligence,"TOPLEFT"}, 120, 0, 100, 18, "^7DEFAULT", function() self:SetColor("^7") end)

	self.controls.edit = new("EditControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, 0, 48, 0, 0, "", nil, "^%C\t\n", nil, nil, 16, true)
	self.controls.edit.width = function()
		return self.width - 16
	end
	self.controls.edit.height = function()
		return self.height - 128
	end
	self.controls.toggleColorCodes = new("ButtonControl", {"TOPRIGHT",self,"TOPRIGHT"}, -10, 70, 160, 20, "Show Color Codes", function()
		self.showColorCodes = not self.showColorCodes
		self:SetShowColorCodes(self.showColorCodes)
	end)
	self:SelectControl(self.controls.edit)
end)

function NotesTabClass:SetShowColorCodes(setting)
	self.showColorCodes = setting
	if setting then
		self.controls.toggleColorCodes.label = "Hide Color Codes"
		self.controls.edit.buf = self.controls.edit.buf:gsub("%^x(%x%x%x%x%x%x)","^_x%1"):gsub("%^(%d)","^_%1")
	else
		self.controls.toggleColorCodes.label = "Show Color Codes"
		self.controls.edit.buf = self.controls.edit.buf:gsub("%^_x(%x%x%x%x%x%x)","^x%1"):gsub("%^_(%d)","^%1")
	end
end

function NotesTabClass:SetColor(color)
	local text = color
	if self.showColorCodes then text = color:gsub("%^x(%x%x%x%x%x%x)","^_x%1"):gsub("%^(%d)","^_%1") end
	if self.controls.edit.sel == nil or self.controls.edit.sel == self.controls.edit.caret then
		self.controls.edit:Insert(text)
	else
		local lastColor = self.controls.edit:GetSelText():match(self.showColorCodes and "^.*(%^_x%x%x%x%x%x%x)" or "^.*(%^x%x%x%x%x%x%x)") or "^7"
		self.controls.edit:ReplaceSel(text..self.controls.edit:GetSelText():gsub(self.showColorCodes and "%^_x%x%x%x%x%x%x" or "%^x%x%x%x%x%x%x", "")..lastColor)
	end
end

function NotesTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if type(node) == "string" then
			self.controls.edit:SetText(node)
		end
	end
	self.lastContent = self.controls.edit.buf
end

function NotesTabClass:Save(xml)
	self:SetShowColorCodes(false)
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
