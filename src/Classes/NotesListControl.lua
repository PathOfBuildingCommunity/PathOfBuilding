-- Path of Building
--
-- Class: Note List
-- Note list control.
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max

local NotesListClass = newClass("NotesListControl", "ListControl", function(self, anchor, rect, notesTab)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, notesTab.notesOrderList)
	self.notesTab = notesTab

	self.label = "^7Notes:"
	self.controls.delete = new("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, {0, -2, 60, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)

	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end

	self.controls.rename = new("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, {-2, 0, 60, 18}, "Rename", function()
		self:RenameNote(notesTab.notes[self.selValue])
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.rename,"LEFT"}, {-2, 0, 60, 18}, "New", function()
		self:RenameNote(notesTab:NewNote(), true)
	end)
end)

-- Triggered when the order of the list has changed
function NotesListClass:OnOrderChange(selIndex, selDragIndex)
	self.notesTab.modFlag = true
end

function NotesListClass:OnSelDelete(index, noteId)
	local note = self.notesTab.notes[noteId]
	if #self.list > 1 then
		main:OpenConfirmPopup("Delete Note", "Are you sure you want to delete '"..(note.title or "Default").."'?", "Delete", function()
			t_remove(self.list, index)
			self.notesTab.notes[noteId] = nil

			self.selIndex = nil
			self.selValue = nil

			if noteId == self.notesTab.activeNoteId then
				self.notesTab:SetActiveNote(self.list[m_max(1, index - 1)])
			end
		end)
	end
end

-- Get the value to display in the list row
function NotesListClass:GetRowValue(column, index, noteId)
	local note = self.notesTab.notes[noteId]
	if column == 1 then
		return (note.title or "Default") .. (noteId == self.notesTab.activeNoteId and "  ^9(Current)" or "")
	end
end

function NotesListClass:RenameNote(note, addOnName)
	local controls = { }
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7Enter name for this note:")
	controls.edit = new("EditControl", nil, {0, 40, 350, 20}, note.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "Save", function()
		note.title = controls.edit.buf
		self.notesTab.modFlag = true

		if addOnName then
			t_insert(self.list, note.id)
			self.selIndex = #self.list
			self.selValue = note.id
		end

		self.notesTab:SetActiveNote(note.id)
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "Cancel", function()
		if addOnName then
			self.notesTab.notes[note.id] = nil
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, note.title and "Rename" or "Note Name", controls, "save", "edit", "cancel")
end

-- Triggered when a note is selected from the list
function NotesListClass:OnSelClick(index, noteId, doubleClick)
	self.notesTab:SaveContentToNote(self.notesTab.activeNoteId)

	if doubleClick and noteId ~= self.notesTab.activeNoteId then
		self.notesTab:SetActiveNote(noteId)
	end
end
