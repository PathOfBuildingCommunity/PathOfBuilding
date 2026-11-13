-- Cyrillic Notes spec clauses 1 and 4.
describe("UTF-8 notes editing", function()
	local utf8 = require("lua-utf8")
	local aura = utf8.char(0x410, 0x443, 0x440, 0x430)
	local helmet = utf8.char(0x428, 0x43b, 0x435, 0x43c)
	local function notes(text)
		local tab = new("NotesTab"):NotesTab({})
		tab.width, tab.height = 800, 600
		tab.controls.edit:SetText(text)
		return tab
	end

	local function press(edit, key, ctrl, clipboard, doubleClick)
		local originalKey, originalPaste = _G.IsKeyDown, _G.Paste
		local originalCursor = _G.GetCursorPos
		_G.IsKeyDown = function(value) return value == "CTRL" and ctrl or false end
		_G.Paste = function() return clipboard end
		_G.GetCursorPos = function() return 20, 140 end
		local success, message = pcall(edit.OnKeyDown, edit, key, doubleClick)
		_G.IsKeyDown, _G.Paste = originalKey, originalPaste
		_G.GetCursorPos = originalCursor
		assert(success, message)
	end

	it("pastes Russian notes with colors, English names and links", function()
		local edit = notes("").controls.edit
		press(edit, "v", true, "^xFFFF77Ёж^7\tSmite\nhttps://pobb.in/example")
		assert.are.equal("^xFFFF77Ёж^7\tSmite\nhttps://pobb.in/example", edit.buf)
	end)

	it("replaces selected notes with pasted UTF-8", function()
		local edit = notes("old").controls.edit
		edit.sel = 1
		press(edit, "v", true, aura .. " Determination")
		assert.are.equal(aura .. " Determination", edit.buf)
	end)

	for _, case in ipairs({
		{ "BACK", "Aё", 4, "A", 2, false },
		{ "DELETE", "ёA", 1, "A", 1, false },
		{ "BACK", helmet .. " Smite", 15, helmet .. " Smit", 14, false },
		{ "BACK", aura .. " ёж", 14, aura .. " ", 10, true },
		{ "DELETE", "ёж Smite", 1, " Smite", 1, true },
		{ "BACK", "А\nё", 6, "А\n", 4, true },
		{ "DELETE", "ё\nА", 1, "\nА", 1, true },
		{ "BACK", "A ёж  ", 9, "A ", 3, true },
		{ "DELETE", "  ёж A", 1, " A", 1, true },
		{ "BACK", "A ", 3, "", 1, true },
		{ "DELETE", " A", 1, "", 1, true },
	}) do
		it(string.format("deletes complete characters with %s at byte %d in %q (ctrl=%s)", case[1], case[3], case[2], tostring(case[6])), function()
			local edit = notes(case[2]).controls.edit
			edit.caret = case[3]
			press(edit, case[1], case[6])
			assert.are.same({ case[4], case[5] }, { edit.buf, edit.caret })
		end)
	end

	it("undoes and redoes deletion of a complete Russian character", function()
		local edit = notes("Smite ё").controls.edit
		press(edit, "BACK", false)
		local deleted = edit.buf
		edit:Undo()
		local restored = edit.buf
		edit:Redo()
		assert.are.same({ "Smite ", "Smite ё", "Smite " }, { deleted, restored, edit.buf })
	end)

	it("moves the caret across complete Russian characters", function()
		local edit = notes("Aё").controls.edit
		press(edit, "LEFT", false)
		local left = edit.caret
		press(edit, "RIGHT", false)
		assert.are.same({ 2, 4 }, { left, edit.caret })
	end)

	it("preserves Russian notes through XML save and load", function()
		local original = notes("^7Ёж & Smite\n" .. aura .. " <Determination>")
		local xml = { elem = "Notes" }
		original:Save(xml)
		local loaded = notes("")
		local parsed = common.xml.ParseXML(common.xml.ComposeXML(xml))
		loaded:Load(parsed[1], "fixture.xml")
		assert.are.equal("^7Ёж & Smite\n" .. aura .. " <Determination>", loaded.controls.edit.buf)
	end)

	it("selects a complete Russian word on double click", function()
		local edit = notes("Smite ёж " .. aura).controls.edit
		edit.caret = 9
		press(edit, "LEFTBUTTON", false, nil, true)
		assert.are.same({ 7, 11 }, { edit.sel, edit.caret })
	end)

	-- Notes repair clause 1: whitespace must not move the caret into a UTF-8 character.
	for _, case in ipairs({
		{ "ёж ", 5, "ёж" },
		{ "ёж  ", 6, "ёж" },
		{ "ёж\t", 5, "ёж" },
		{ "ёж\nSmite", 5, "ёж" },
		{ "— ", 4, "—" },
		{ "™\nSmite", 4, "™" },
	}) do
		it(string.format("selects a complete word before whitespace at byte %d in %q", case[2], case[1]), function()
			local edit = notes(case[1]).controls.edit
			edit.caret = case[2]
			press(edit, "LEFTBUTTON", false, nil, true)
			assert.are.equal(case[3], edit:GetSelText())
		end)
	end
end)
