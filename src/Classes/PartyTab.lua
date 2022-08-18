-- Path of Building
--
-- Module: Party Tab
-- Party tab for the current build.
--
local t_insert = table.insert

local PartyTabClass = newClass("PartyTab", "ControlHost", "Control", function(self, build)
	self.ControlHost()
	self.Control()

	self.build = build
	
	self.buffExports = {}

	self.lastContent = ""
	self.showColorCodes = false

	local notesDesc = [[^7Party stuff	]]
	self.controls.notesDesc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, notesDesc)

	--self, anchor, x, y, width, height, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom
	self.controls.editAuras = new("EditControl", {"TOPLEFT",self.controls.notesDesc,"TOPLEFT"}, 0, 48, 0, 0, "", nil, "^%C\t\n", nil, function() self.build.buildFlag = true end, 16, true)
	self.controls.editAuras.width = function()
		return self.width - 16
	end
	self.controls.editAuras.height = function()
		return self.height - 128
	end
	self:SelectControl(self.controls.editAuras)
end)

function PartyTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if type(node) == "string" then
			self.controls.editAuras:SetText(node)
		end
	end
	self.lastContent = self.controls.editAuras.buf
end

function PartyTabClass:Save(xml)
	t_insert(xml, self.controls.editAuras.buf)
	t_insert(xml, PartyTabClass:exportAuras())
	self.lastContent = self.controls.editAuras.buf
end

function PartyTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self.controls.editAuras:Undo()
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.controls.editAuras:Redo()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	self.modFlag = (self.lastContent ~= self.controls.editAuras.buf)
end

function PartyTabClass:ParseAuras()
	local allyBuffs = {}
	local mode = "Name"
	local currentName
	for line in self.controls.editAuras.buf:gmatch("([^\n]*)\n?") do
		if mode == "Name" and line ~= "" then
			currentName = line
			allyBuffs[currentName] = {}
			allyBuffs[currentName].modList = new("ModList")
			mode = "Effect"
		elseif mode == "Effect" then
			allyBuffs[currentName].effectMult = tonumber(line)
			mode = "Stats"
		elseif line == "---" then
			mode = "Name"
		else
			local mods, extra = modLib.parseMod(line)
			if mods then
				local source = "Ally Mods"
				for i = 1, #mods do
					local mod = mods[i]

					if mod then
						mod = modLib.setSource(mod, source)
						allyBuffs[currentName].modList:AddMod(mod)
					end
				end
			end
		end
	end
	return allyBuffs
end

function PartyTabClass:setBuffExports(buffExports)
	self.buffExports = copyTable(buffExports, true)
end

function PartyTabClass:exportAuras()
	if not self.buffExports then
		return ""
	end
	local buf = ""
	for buffName, buff in pairs(self.buffExports) do
		if #buf > 0 then
			buf = buf.."\n"
		end
		buf = buf..buffName.."\n"..tostring(buff.effectMult).."\n"
		for _, mod in ipairs(buff.modList) do
			buf = buf..modLib.formatMod(mod)
		end
		buf = buf.."---"
	end
	
	return buf
end