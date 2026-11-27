describe("Common", function()
	describe("Class creation and use", function()
		it("produces error when parent constructors are not called", function()
			local ParentClass = newClass("ConstructorTestParentClass")
			function ParentClass:ConstructorTestParentClass()
				return self
			end
			local ChildClass = newClass("ConstructorTestProblemChild", "ConstructorTestParentClass")
			function ChildClass:ConstructorTestProblemChild()
				-- Intentionally does not call self:ConstructorTestParentClass()
				return self
			end
			common.classes.ConstructorTestParent = ParentClass
			common.classes.ConstructorTestProblemChild = ChildClass

			assert.has_error(function()
				new("ConstructorTestProblemChild"):ConstructorTestProblemChild()
			end, "Parent class 'ConstructorTestParentClass' of class 'ConstructorTestProblemChild' must be initialised")
			common.classes.ConstructorTestParent = nil
			common.classes.ConstructorTestProblemChild = nil
		end)
		it("produces an error if additional arguments are passed", function()
			local StupidClass = newClass("NewAbuse")
			function StupidClass:NewAbuse(someParam)
				return self
			end

			common.classes.NewAbuse = StupidClass

			assert.has_no.errors(function()
				local newObj = new("NewAbuse"):NewAbuse("fish")
			end)
			assert.has_error(function()
				local newObj = new("NewAbuse", "look I'm using the old syntax")
			end)
		end)
		it("produces an error if it calls a parent class without giving it self", function()
			local ParentClass = newClass("ConstructorTestParentClass")
			function ParentClass:ConstructorTestParentClass()
				return self
			end

			local ChildClass = newClass("ConstructorTestProblemChild", "ConstructorTestParentClass")
			function ChildClass:ConstructorTestProblemChild()
				self.ConstructorTestParentClass()
				return self
			end

			common.classes.ConstructorTestParent = ParentClass
			common.classes.ConstructorTestProblemChild = ChildClass

			assert.has_error(function()
				new("ConstructorTestProblemChild"):ConstructorTestProblemChild()
			end)
			common.classes.ConstructorTestParent = nil
			common.classes.ConstructorTestProblemChild = nil
		end)
		it("produces an error if its constructor doesn't return the object", function()
			local StupidClass = newClass("StupidClass")
			function StupidClass:StupidClass()
			end

			common.classes.StupidClass = StupidClass

			assert.has_error(function()
				new("StupidClass"):StupidClass()
			end, "Class StupidClass constructor did not return a value")
		end)
		it("produces an error if its constructor has not been called", function()
			local StupidClass = newClass("StupidClass")
			function StupidClass:StupidClass()
				return self
			end

			function StupidClass:Clear()
			end

			common.classes.StupidClass = StupidClass

			assert.has_error(function()
				local object = new("StupidClass")
				return object.lines
			end)
			assert.has_error(function()
				local object = new("StupidClass")
				object:Clear()
			end)
			assert.has_no.errors(function()
				local object = new("StupidClass"):StupidClass()
				local x = object.lines
				object:Clear()
			end)
			common.classes.StupidClass = nil
		end)
	end)
	it("WrapString wraps before the word that overflows the width", function()
		-- Count visible characters so widths are character counts
		local drawStringWidth = _G.DrawStringWidth
		_G.DrawStringWidth = function(height, font, text)
			return #StripEscapes(text)
		end
		finally(function()
			_G.DrawStringWidth = drawStringWidth
		end)
		local function wrap(str, width)
			return copyTable(main:WrapString(str, 16, width))
		end

		assert.are.same({ "aa bb", "cc dd" }, wrap("aa bb cc dd", 5))
		assert.are.same({ "abc", "de" }, wrap("abc de", 3))
		assert.are.same({ "^7abcd", "^xFF0000efgh", "ij" }, wrap("^7abcd ^xFF0000efgh ij", 4))
		assert.are.same({ "abcdefgh", "xy" }, wrap("abcdefgh xy", 3))
	end)
end)