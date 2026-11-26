describe("TestBrandAttachment", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	it("parses the Seeker Runes line split across two lines", function()
		local node
		for _, treeNode in pairs(build.spec.tree.nodes) do
			if treeNode.dn == "Seeker Runes" then
				node = treeNode
			end
		end
		assert.is_not_nil(node)
		assert.is_nil(node.unknown)
		assert.is_nil(node.extra)
		local found = false
		for _, mod in ipairs(node.modList) do
			if mod.name == "BrandAttachmentRange" then
				found = true
				assert.are.equals("INC", mod.type)
				assert.are.equals(20, mod.value)
			end
		end
		assert.is_true(found)
	end)

	it("scales unattached brand attachment range with seconds unattached up to the maximum", function()
		build.skillsTab:PasteSocketGroup("Armageddon Brand 20/0  1")
		-- 3.28+ wording, and the 3.11 to 3.27 wording kept by builds saved on older trees
		for _, text in ipairs({ "per second, up to a maximum of 100%", "per second, up to 100%" }) do
			build.configTab.input.customMods = "Unattached Brands gain 20% increased Brand Attachment Range "..text
			local base
			for _, case in ipairs({ { seconds = 0, inc = 0 }, { seconds = 3, inc = 60 }, { seconds = 10, inc = 100 } }) do
				build.configTab.input.brandUnattachedSeconds = case.seconds
				build.configTab:BuildModList()
				runCallback("OnFrame")
				local output = build.calcsTab.mainOutput
				base = base or output.BrandAttachmentRange
				assert.are.equals(base * (1 + case.inc / 100), output.BrandAttachmentRange)
			end
		end
	end)
end)
