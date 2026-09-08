describe("EditControl", function()
	local originalDrawString
	local originalDrawStringCursorIndex
	local originalDrawStringWidth
	local originalGetCursorPos
	local originalIsKeyDown

	local function newMultilineControl(text, lineHeight)
		return new("EditControl"):EditControl(nil, { 0, 0, 200, 100 }, text, nil, "^%C\t\n", nil, nil, lineHeight)
	end

	before_each(function()
		originalDrawString = _G.DrawString
		originalDrawStringCursorIndex = _G.DrawStringCursorIndex
		originalDrawStringWidth = _G.DrawStringWidth
		originalGetCursorPos = _G.GetCursorPos
		originalIsKeyDown = _G.IsKeyDown
	end)

	after_each(function()
		_G.DrawString = originalDrawString
		_G.DrawStringCursorIndex = originalDrawStringCursorIndex
		_G.DrawStringWidth = originalDrawStringWidth
		_G.GetCursorPos = originalGetCursorPos
		_G.IsKeyDown = originalIsKeyDown
	end)

	it("maps multiline cursor Y to the displayed line", function()
		local control = newMultilineControl("aa\n\tbb\n\n^1café", 14)
		local calls = { }
		_G.DrawStringCursorIndex = function(height, font, text, cursorX, cursorY)
			table.insert(calls, { height, font, text, cursorX, cursorY })
			return #text + 1
		end

		assert.are.equal(7, control:GetCursorIndex(14, 9, 14 + 7))
		assert.are.same({ 14, "VAR", "\tbb", 9, 0 }, calls[#calls])
		assert.are.equal(8, control:GetCursorIndex(14, 9, 14 * 2 + 7))
		assert.are.same({ 14, "VAR", "", 9, 0 }, calls[#calls])
		assert.are.equal(#control.buf + 1, control:GetCursorIndex(14, 9, 1000))
		assert.are.same({ 14, "VAR", "^1café", 9, 0 }, calls[#calls])
		assert.are.equal(3, control:GetCursorIndex(14, 9, -10))
		assert.are.same({ 14, "VAR", "aa", 9, 0 }, calls[#calls])
	end)

	it("uses content coordinates for mouse-down and drag hit testing", function()
		local control = newMultilineControl("aa\nbb\ncc\ndd", 14)
		local calls = { }
		control.IsMouseOver = function()
			return true
		end
		control.GetMouseOverControl = function()
			return nil
		end
		control.UpdateScrollBars = function()
		end
		control.ScrollCaretIntoView = function()
		end
		_G.DrawStringCursorIndex = function(_, _, text, cursorX, cursorY)
			table.insert(calls, { text = text, cursorX = cursorX, cursorY = cursorY })
			return 2
		end
		_G.IsKeyDown = function(key)
			return key == "LEFTBUTTON"
		end

		control.controls.scrollBarH.offset = 5
		control.controls.scrollBarV.offset = 14
		_G.GetCursorPos = function()
			return 12, 23
		end
		control:OnKeyDown("LEFTBUTTON")
		assert.are.equal(8, control.caret)
		assert.are.same({ text = "cc", cursorX = 15, cursorY = 0 }, calls[#calls])

		control.controls.scrollBarH.offset = 3
		control.controls.scrollBarV.offset = 28
		_G.GetCursorPos = function()
			return 11, 23
		end
		control.hasFocus = true
		control.drag = true
		control:Draw({ x = 0, y = 0, width = 200, height = 100 }, true)
		assert.are.equal(11, control.caret)
		assert.are.same({ text = "dd", cursorX = 12, cursorY = 0 }, calls[#calls])
	end)

	it("keeps the host multiline behavior for single-line controls", function()
		local control = new("EditControl"):EditControl(nil, { 0, 0, 200, 20 }, "aa\nbb")
		_G.DrawStringCursorIndex = function(height, font, text, cursorX, cursorY)
			assert.are.equal("aa\nbb", text)
			assert.are.equal(23, cursorY)
			return 4
		end

		assert.are.equal(4, control:GetCursorIndex(16, 9, 23))
	end)

	it("moves vertically by the logical line height at depth", function()
		local lines = { }
		for i = 1, 30 do
			lines[i] = "ab"
		end
		local control = newMultilineControl(table.concat(lines, "\n"), 14)
		local function lineStart(line)
			return (line - 1) * 3 + 1
		end
		_G.DrawStringWidth = function(_, _, text)
			return #text
		end
		_G.DrawStringCursorIndex = function(_, _, text, _, cursorY)
			assert.are.equal("ab", text)
			assert.are.equal(0, cursorY)
			return 2
		end
		control.caret = lineStart(20) + 1

		control:MoveCaretVertically(14)
		assert.are.equal(lineStart(21) + 1, control.caret)
		control:MoveCaretVertically(-14)
		assert.are.equal(lineStart(20) + 1, control.caret)
	end)

	it("draws multiline text on the logical line grid while unfocused", function()
		local control = newMultilineControl("first\n\nthird", 14)
		local calls = { }
		_G.DrawString = function(_, top, _, height, font, text)
			table.insert(calls, { top = top, height = height, font = font, text = text })
		end
		control.hasFocus = false

		control:Draw({ x = 0, y = 0, width = 200, height = 100 }, true)

		local textCalls = { }
		for _, call in ipairs(calls) do
			if call.text == "first" or call.text == "" or call.text == "third" then
				table.insert(textCalls, call)
			end
		end
		assert.are.same({
			{ top = 0, height = 14, font = "VAR", text = "first" },
			{ top = 14, height = 14, font = "VAR", text = "" },
			{ top = 28, height = 14, font = "VAR", text = "third" },
		}, textCalls)
	end)
end)
