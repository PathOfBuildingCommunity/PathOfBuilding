describe("Utils.stringify", function()
	local utils = require("Modules/Utils")

	-- Parses stringify output back into a Lua value
	local function serializeAndLoad(value, allowNewlines)
		local str = utils.stringify(value, allowNewlines)
		local chunk, err = loadstring("return " .. str)
		assert.is_truthy(chunk)
		return chunk(), str
	end

	describe("scalars", function()
		it("stringifies strings with quotes", function()
			assert.equal('"hello"', utils.stringify("hello"))
		end)

		it("strips newlines from strings by default", function()
			assert.equal('"a b"', utils.stringify("a\nb"))
		end)

		it("preserves newlines when allowed", function()
			local out = serializeAndLoad("a\nb", true)
			assert.equal("a\nb", out)
		end)

		it("does not use long string form for newline-free strings", function()
			assert.equal('"ab"', utils.stringify("ab", true))
		end)

		it("escapes quotes and backslashes", function()
			local input = 'a"b\\c'
			local out = serializeAndLoad(input, true)
			assert.equal(input, out)
		end)

		it("preserves carriage returns and long-string delimiters when allowed", function()
			local input = "a\r\n]]b"
			local out = serializeAndLoad(input, true)
			assert.equal(input, out)
		end)

		it("normalizes all newline forms when newlines are disabled", function()
			assert.equal('"a b c"', utils.stringify("a\r\nb\rc"))
		end)

		it("stringifies numbers", function()
			assert.equal("42", utils.stringify(42))
			assert.equal("-3.5", utils.stringify(-3.5))
		end)

		it("stringifies booleans", function()
			assert.equal("true", utils.stringify(true))
			assert.equal("false", utils.stringify(false))
		end)

		it("stringifies nil", function()
			assert.equal("nil", utils.stringify(nil))
		end)

		-- supposedly these are valid table keys, but like come on
		it("errors on disallowed types", function()
			assert.has_error(function() utils.stringify(function() end) end)
			assert.has_error(function() utils.stringify({ [function() end] = "hello" }) end)
		end)
	end)

	describe("tables", function()
		it("serializes and loads an empty table", function()
			local out = serializeAndLoad({})
			assert.same({}, out)
		end)

		it("serializes and loads an array using array syntax", function()
			local input = { 1, 2, 3 }
			local out, str = serializeAndLoad(input)
			assert.same(input, out)
			-- array entries should not include explicit keys
			assert.is_nil(str:find("%[1%]"))
		end)

		it("serializes and loads a string-keyed map", function()
			local input = { foo = "bar", baz = 1 }
			local out = serializeAndLoad(input)
			assert.same(input, out)
		end)

		it("serializes and loads nested tables (no mixed array/map levels)", function()
			local input = { a = { b = { c = { deep = true, value = 3 } } }, list = { "x", "y" } }
			local out = serializeAndLoad(input)
			assert.same(input, out)
		end)

		it("sorts map keys deterministically", function()
			local str = utils.stringify({ c = 1, a = 1, b = 1 })
			local posA = str:find('%["a"%]')
			local posB = str:find('%["b"%]')
			local posC = str:find('%["c"%]')
			assert.is_truthy(posA < posB and posB < posC)
		end)

		it("serializes and loads numeric (non-sequential) keys", function()
			local input = { [5] = "five", [10] = "ten" }
			local out = serializeAndLoad(input)
			assert.same(input, out)
		end)

		it("serializes and loads multiline string values when allowed", function()
			local input = { text = "line1\nline2" }
			local out = serializeAndLoad(input, true)
			assert.same(input, out)
		end)

		it("serializes and loads escaped multiline string keys", function()
			local input = { ['a"\\b\n]]c'] = true }
			local out = serializeAndLoad(input, true)
			assert.same(input, out)
		end)

		it("serializes and loads mixed tables", function()
			local input = { "one", "two", six = 7, 3, 4, five = "six" }
			local str = utils.stringify(input, false, 1)
			assert.equal([[{
	"one",
	"two",
	3,
	4,
	["five"] = "six",
	["six"] = 7,
}]], str)
			local out = serializeAndLoad(input)
			assert.same(input, out)
		end)
	end)
end)
