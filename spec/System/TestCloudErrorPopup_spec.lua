describe("OpenCloudErrorPopup", function()
	it("works when the host does not provide GetCloudProvider", function()
		local originalGetCloudProvider = _G.GetCloudProvider
		_G.GetCloudProvider = nil
		local ok, err = pcall(function()
			main:OpenCloudErrorPopup("SomeBuild.xml")
		end)
		_G.GetCloudProvider = originalGetCloudProvider
		if ok then
			main:ClosePopup()
		end
		assert.is_true(ok, tostring(err))
	end)
end)
