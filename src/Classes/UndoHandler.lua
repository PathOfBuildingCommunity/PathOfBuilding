-- Path of Building
--
-- Class: Undo Handler
-- Handler for classes that need to provide undo/redo functionality
-- Classes that use this must define 2 functions:
-- undoState = :CreateUndoState()	Returns a new undo state that reflects the current state
-- :RestoreUndoState(undoState)		Reverts the current state to the given undo state
--
local t_insert = table.insert
local t_remove = table.remove

---@class UndoHandler
---@field CreateUndoState fun() Must be manually defined. Creates a state that can be restored
---@field RestoreUndoState fun(state: any) Must be manually defined. Restores a state created by calling CreateUndoState()
local UndoHandlerClass = newClass("UndoHandler")

function UndoHandlerClass:UndoHandler()
	self.undo = { }
	self.redo = { }
	return self
end

-- Initialises the undo/redo buffers
-- Should be called after the current state is first loaded/initialised
function UndoHandlerClass:ResetUndo()
	self.undo = wipeTable(self.undo)
	self.redo = wipeTable(self.redo)
	self.undo[1] = self:CreateUndoState()
end

-- Adds a new undo state to the undo buffer, and also clears the redo buffer
-- Should be called after the user makes a change to the current state
---@param noClearRedo boolean?
function UndoHandlerClass:AddUndoState(noClearRedo)
	t_insert(self.undo, 1, self:CreateUndoState())
	self.undo[102] = nil
	self.modFlag = true
	if not noClearRedo then
		self.redo = wipeTable(self.redo)
	end
end

-- Reverts the current state to the previous undo state
function UndoHandlerClass:Undo()
	if self.undo[2] then
		t_insert(self.redo, 1, t_remove(self.undo, 1))
		self:RestoreUndoState(t_remove(self.undo, 1))
		self:AddUndoState(true)
	end
end

-- Reverts the most recent undo operation
function UndoHandlerClass:Redo()
	if self.redo[1] then
		self:RestoreUndoState(t_remove(self.redo, 1))
		self:AddUndoState(true)
	end
end
