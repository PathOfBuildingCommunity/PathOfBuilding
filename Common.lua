-- Path of Building
--
-- Module: Common
-- Libaries, functions and classes used by various modules.
--

common = { }

-- External libraries
common.curl = require("lcurl")
common.xml = require("xml")
common.json = require("dkjson")
common.base64 = require("base64")
common.newEditField = require("simplegraphic/editfield")

-- Class library
common.classes = { }
-- NewClass("<className>"[, "<parentClassName>"[, "<parentClassName>" ...]], constructorFunc)
function common.NewClass(className, ...)
	local class = { }
	common.classes[className] = class
	class.__index = class
	class._className = className
	local numVarArg = select("#", ...)
	class._constructor = select(numVarArg, ...)
	if numVarArg > 1 then
		-- Build list of parent classes
		class._parents = { }
		for i = 1, numVarArg - 1 do
			local parentName = select(i, ...)
			if not common.classes[parentName] then
				error("Parent class '"..className.."' not defined")
			end
			class._parents[i] = common.classes[parentName]
		end
		if #class._parents == 1 then
			-- Single inheritance
			setmetatable(class, class._parents[1]) 
		else
			-- Multiple inheritance
			setmetatable(class, {
				__index = function(self, key)
					for _, parent in ipairs(class._parents) do
						local val = class._parents[key]
						if val ~= nil then
							return val
						end
					end
				end,
			})
		end
	end
	return class
end
function common.New(className, ...)
	local class = common.classes[className]
	if not class then
		error("Class '"..className.."' not defined")
	end
	if not class._constructor then
		error("Class '"..className.."' has no constructor")
	end
	local object = setmetatable({ }, class)
	if class._parents then
		-- Add parent class proxies
		for _, parent in pairs(class._parents) do
			object[parent._className] = setmetatable({ }, {
				__index = function(self, key)
					local v = rawget(object, key)
					if v ~= nil then
						return v
					else
						return parent[key]
					end
				end,
				__newindex = object,
				__call = function(...)
					if not parent._constructor then
						error("Parent class '"..parent._className.."' of class '"..className.."' has no constructor")
					end
					parent._constructor(...)
				end,
			})
		end
	end
	class._constructor(object, ...)
	return object
end

-- UI Controls
LoadModule("Classes/EditControl")
LoadModule("Classes/ButtonControl")
LoadModule("Classes/DropDownControl")

-- Process input events for a host object with a list of controls
function common.controlsInput(host, inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if host.selControl then
				if host.selControl:OnKeyDown(event.key, event.doubleClick) then
					host.selControl = nil
				end
				inputEvents[id] = nil
			elseif event.key == "LEFTBUTTON" then
				local cx, cy = GetCursorPos()
				for _, control in pairs(host.controls) do
					if control.IsMouseOver and control:IsMouseOver() and control.OnKeyDown then
						if not control:OnKeyDown(event.key, event.doubleClick) then
							host.selControl = control
						end
						inputEvents[id] = nil
						break
					end
				end
			end
		elseif event.type == "KeyUp" then
			if host.selControl then
				if host.selControl.OnKeyUp and host.selControl:OnKeyUp(event.key) then
					host.selControl = nil
				end
				inputEvents[id] = nil
			end
		elseif event.type == "Char" then
			if host.selControl then
				if host.selControl.OnChar and host.selControl:OnChar(event.key) then
					host.selControl = nil
				end
				inputEvents[id] = nil
			end
		end
	end	
end

-- Draw host object's controls
function common.controlsDraw(host, ...)
	for _, control in pairs(host.controls) do
		if control ~= host.selControl then
			control:Draw(...)
		end
	end
	if host.selControl then
		host.selControl:Draw(...)
	end

end

-- Draw simple popup message box
function common.drawPopup(r, g, b, fmt, ...)
	local screenW, screenH = GetScreenSize()
	SetDrawColor(0, 0, 0, 0.5)
	DrawImage(nil, 0, 0, screenW, screenH)
	local txt = string.format(fmt, ...)
	local w = DrawStringWidth(20, "VAR", txt) + 20
	local h = (#txt:gsub("[^\n]","") + 2) * 20
	local ox = (screenW - w) / 2
	local oy = (screenH - h) / 2
	SetDrawColor(1, 1, 1)
	DrawImage(nil, ox, oy, w, h)
	SetDrawColor(r, g, b)
	DrawImage(nil, ox + 2, oy + 2, w - 4, h - 4)
	SetDrawColor(1, 1, 1)
	DrawImage(nil, ox + 4, oy + 4, w - 8, h - 8)
	DrawString(0, oy + 10, "CENTER", 20, "VAR", txt)
end

-- Make a copy of a table and all subtables
function copyTable(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			out[k] = copyTable(v)
		else
			out[k] = v
		end
	end
	return out
end

-- Wipe all keys from the table and return it, or return a new table if no table provided
function wipeTable(tbl)
	if not tbl then
		return { }
	end
	for k in pairs(tbl) do
		tbl[k] = nil
	end
	return tbl
end

-- Search a table for a value, and return the corresponding key
function isValueInTable(tbl, val)
	for k, v in pairs(tbl) do
		if val == v then
			return k
		end
	end
end

-- Search an array for a value, and return the corresponding array index
function isValueInArray(tbl, val)
	for i, v in ipairs(tbl) do
		if val == v then
			return i
		end
	end
end
