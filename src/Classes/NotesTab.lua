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

	self.notes = { }
	self.notesOrderList = { }

	self.showColorCodes = false

	local listSize = 250

	local notesDesc = [[^7You can use Ctrl +/- (or Ctrl+Scroll) to zoom in and out and Ctrl+0 to reset.
This field also supports different colors.  Using the caret symbol (^) followed by a Hex code or a number (0-9) will set the color.
Below are some common color codes PoB uses:	]]
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, {8, 8, 150, 16}, notesDesc)
	self.controls.normal = new("ButtonControl", {"TOPLEFT",self.controls.notesDesc,"TOPLEFT"}, {0, 48, 100, 18}, colorCodes.NORMAL.."NORMAL", function() self:SetColor(colorCodes.NORMAL) end)
	self.controls.magic = new("ButtonControl", {"TOPLEFT",self.controls.normal,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.MAGIC.."MAGIC", function() self:SetColor(colorCodes.MAGIC) end)
	self.controls.rare = new("ButtonControl", {"TOPLEFT",self.controls.magic,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.RARE.."RARE", function() self:SetColor(colorCodes.RARE) end)
	self.controls.unique = new("ButtonControl", {"TOPLEFT",self.controls.rare,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.UNIQUE.."UNIQUE", function() self:SetColor(colorCodes.UNIQUE) end)
	self.controls.fire = new("ButtonControl", {"TOPLEFT",self.controls.normal,"TOPLEFT"}, {0, 18, 100, 18}, colorCodes.FIRE.."FIRE", function() self:SetColor(colorCodes.FIRE) end)
	self.controls.cold = new("ButtonControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.COLD.."COLD", function() self:SetColor(colorCodes.COLD) end)
	self.controls.lightning = new("ButtonControl", {"TOPLEFT",self.controls.cold,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.LIGHTNING.."LIGHTNING", function() self:SetColor(colorCodes.LIGHTNING) end)
	self.controls.chaos = new("ButtonControl", {"TOPLEFT",self.controls.lightning,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.CHAOS.."CHAOS", function() self:SetColor(colorCodes.CHAOS) end)
	self.controls.strength = new("ButtonControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, {0, 18, 100, 18}, colorCodes.STRENGTH.."STRENGTH", function() self:SetColor(colorCodes.STRENGTH) end)
	self.controls.dexterity = new("ButtonControl", {"TOPLEFT",self.controls.strength,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.DEXTERITY.."DEXTERITY", function() self:SetColor(colorCodes.DEXTERITY) end)
	self.controls.intelligence = new("ButtonControl", {"TOPLEFT",self.controls.dexterity,"TOPLEFT"}, {120, 0, 100, 18}, colorCodes.INTELLIGENCE.."INTELLIGENCE", function() self:SetColor(colorCodes.INTELLIGENCE) end)
	self.controls.default = new("ButtonControl", {"TOPLEFT",self.controls.intelligence,"TOPLEFT"}, {120, 0, 100, 18}, "^7DEFAULT", function() self:SetColor("^7") end)

	-- Notes group list
	self.controls.noteList = new("NotesListControl", { "TOPLEFT", self.controls.strength, "TOPLEFT" }, { 0, 48, listSize - 16, 300 }, self)

	self.controls.edit = new("EditControl", {"TOPLEFT",self.controls.strength,"TOPLEFT"}, {listSize, 48, 0, 0}, "", nil, "^%C\t\n", nil, nil, 16, true)
	self.controls.edit.width = function()
		return self.width - listSize - 16
	end
	self.controls.edit.height = function()
		return self.height - 148
	end
	self.controls.toggleColorCodes = new("ButtonControl", {"TOPRIGHT",self,"TOPRIGHT"}, {-10, 70, 160, 20}, "Show Color Codes", function()
		self.showColorCodes = not self.showColorCodes
		self:SetShowColorCodes(self.showColorCodes)
	end)

	self:SetActiveNote(1)

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
	self.activeNoteId = 0
	self.notes = { }
	self.noteOrderList = { }

	for index, node in ipairs(xml) do
		-- backwards compatibility
		if type(node) == "string" then
			self.notesOrderList[1] = 1
			self.notes[1] = { 
				id = 1, 
				content = node 
			}
	
			self:SetActiveNote(1)
		else 
			local savedNoteId = tonumber(node.attrib.id)
			self.notesOrderList[index] = savedNoteId

			self.notes[savedNoteId] = { 
				id = savedNoteId, 
				title = node.attrib.title, 
				content = node[1] or ""
			}

			if node.attrib.active ~= nil then
				self:SetActiveNote(savedNoteId)
			end
		end
	end

	self.modFlag = false
end

function NotesTabClass:Save(xml)
	self:SetShowColorCodes(false)

	self.notes[self.activeNoteId].content = self.controls.edit.buf

	for _, noteId in ipairs(self.notesOrderList) do
		local attrib = {
			id = tostring(noteId),
			title = self.notes[noteId].title,
		}

		if self.activeNoteId == noteId then
			attrib.active = "1"
		end

		local note = {
			elem = "Note",
			attrib = attrib,
			[1] = self.notes[noteId].content
		}

		t_insert(xml, note)
	end
end

function NotesTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				if self.controls.edit.hasFocus then
					self.controls.edit:Undo()
				end
			elseif event.key == "y" and IsKeyDown("CTRL") then
				if self.controls.edit.hasFocus then
					self.controls.edit:Redo()
				end
			end
		end
	end
	
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	self.modFlag = (self.notes[self.activeNoteId].content ~= self.controls.edit.buf) or self.modFlag
end

-- Creates a new note
function NotesTabClass:NewNote(noteId)
	local note = { id = noteId, content = "" }

	if not noteId then
		note.id = 1
		while self.notes[note.id] do
			note.id = note.id + 1
		end
	end

	self.notes[note.id] = note

	return note
end

-- Changes the active note
function NotesTabClass:SetActiveNote(noteId)
	-- Initialize note if needed
	if not self.notesOrderList[1] then
		self.notesOrderList[1] = 1
		self:NewNote(1)
	end

	if not noteId then
		noteId = self.activeNoteId
	end

	if not self.notes[noteId] then
		noteId = self.notesOrderList[1]
	end

	self.activeNoteId = noteId
	self.notes[self.activeNoteId].lastContent = self.controls.edit.buf
	self.controls.edit:SetText(self.notes[noteId].content)
end

function NotesTabClass:SaveContentToNote(noteId) 
	self.notes[noteId].content = self.controls.edit.buf
end
