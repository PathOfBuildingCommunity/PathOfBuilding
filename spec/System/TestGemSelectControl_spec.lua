describe("GemSelectControl", function()
	local function makeControl()
		local change
		local skillsTab = {
			showSupportGemTypes = "ALL",
			defaultGemLevel = 20,
			build = {
				characterLevel = 100,
				data = { gems = { } },
			},
		}
		local control = new("GemSelectControl", nil, { 0, 0, 300, 20 }, skillsTab, 1, function(...)
			change = { ... }
		end)
		control.gems = {
			["Default:Arc"] = { name = "Arc", grantedEffect = { } },
			["Default:Fireball"] = { name = "Fireball", grantedEffect = { } },
		}
		control.sortCache = {
			canSupport = { },
			dps = {
				["Default:Arc"] = 2,
				["Default:Fireball"] = 1,
			},
		}
		control.skillsTab.sortGemsByDPS = true
		control.list = { "Default:Fireball", "Default:Arc" }
		control.searchStr = ""
		control.ScrollSelIntoView = function() end
		return control, function() return change end
	end

	it("keeps the selected gem aligned with a lazy DPS sort", function()
		local control = makeControl()
		control.buf = "Fireball"

		control:SortCurrentList()

		assert.are.equal("Default:Arc", control.list[1])
		assert.are.equal(2, control.selIndex)
	end)

	it("restores and releases focus on a cancelled outside click", function()
		local control, getChange = makeControl()
		control.buf = "Arc"
		control.initialBuf = "Fireball"
		control.dropped = true
		control.IsShown = function() return true end
		control.IsEnabled = function() return true end
		control.IsMouseOver = function() return false end

		assert.is_nil(control:OnKeyDown("LEFTBUTTON"))
		assert.are.equal("Fireball", control.buf)
		assert.are.equal(2, control.selIndex)
		assert.are.same({ "Fireball", false, true, true }, getChange())
	end)

	it("allows click-through after selecting a gem", function()
		local control, getChange = makeControl()
		control.buf = "Fireball"
		control.initialBuf = "Fireball"
		control.dropped = true
		control.hoverSel = 2
		control.IsShown = function() return true end
		control.IsEnabled = function() return true end
		control.IsMouseOver = function() return true end

		assert.is_nil(control:OnKeyDown("LEFTBUTTON"))
		assert.are.equal("Arc", control.buf)
		assert.are.same({ "Arc", true, nil, true }, getChange())
	end)
end)
