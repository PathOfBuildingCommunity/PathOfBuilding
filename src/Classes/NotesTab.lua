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

	local DescriptionText = [[^7This field supports URLs and different colors. URLs can accessed by first clicking on the url and selecting either Ctrl-RightClick or Ctrl-u.
	Colors can be used by using the caret symbol (^) followed by a Hex code or a number (0-9) will set the color. Below are some common color codes PoB uses:	]]
	self.controls.colorDoc = new("LabelControl", {"TOPLEFT",self,"TOPLEFT"}, 8, 8, 150, 16, DescriptionText)
	self.controls.normal = new("ButtonControl", {"TOPLEFT",self.controls.colorDoc,"TOPLEFT"}, 0, 32, 100, 18, colorCodes.NORMAL.."NORMAL", function() self:SetColor(colorCodes.NORMAL) end)
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

	self.controls.edit = new("EditControl", {"TOPLEFT",self.controls.fire,"TOPLEFT"}, 0, 48, 0, 0, "", nil, "^%C\t\n", nil, nil, 16)
	self.controls.edit.width = function()
		return self.width - 16
	end
	self.controls.edit.height = function()
		return self.height - 112
	end
	self.controls.edit.allowURLs = true
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
	local urlList = { }
	local str = self.controls.edit.buf
	local function FindURLs()
		-- find any urls in the edit buffer
		local first = 0
		local last = 0
		wipeTable(urlList)
		while true do
			first, last = str:find("(http[s]-:.-)%s", last+1)
			if not first then break end
			t_insert(urlList, { first, last, str:sub(first, last-1) })
		end
		return urlList
	end

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
		elseif event.type == "KeyUp" then
			local ctrl = IsKeyDown("CTRL")
			if ctrl and ( event.key == "RIGHTBUTTON" or event.key == "u" ) then
				caret = self.controls.edit.caret
				if FindURLs() then
					for _, entry in ipairs(urlList) do
						if caret >= entry[1] and caret < entry[2] then
							os.execute('c:/windows/explorer.exe "'..entry[3]..'"')
							return
						end
					end
				end
			end
		end
	end
	self:ProcessControlsInput(inputEvents, viewPort)

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)

	self.modFlag = (self.lastContent ~= self.controls.edit.buf)
end
