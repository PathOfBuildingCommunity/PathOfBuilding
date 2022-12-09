-- Dat View
--
-- Class: GGPK Source List
-- GGPK source list control.
--
local GGPKSourceListClass = newClass("GGPKSourceListControl", "ListControl", function(self, anchor, x, y, width, height)
	self.ListControl(anchor, x, y, width, height, 16, false, false, main.datSources)
	self.colList = {
		{ width = width * 0.25, label = "Name", sortable = true },
		{ width = width * 0.75, label = "Spec File Path" },
	}
	self.colLabels = true
	self.controls.new = new("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, -62, -4, 60, 18, "New", function()
		local datSource = {}
		self:EditDATSource(datSource, true)
	end)
	self.controls.delete = new("ButtonControl", {"LEFT",self.controls.new,"RIGHT"}, 4, 0, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
end)

function GGPKSourceListClass:EditDATSource(datSource, newSource)
	local controls = { }
	controls.labelLabel = new("LabelControl", nil, -30, 20, 0, 16, "^7Name:")
	controls.label = new("EditControl", nil, 85, 20, 180, 20, datSource.label, nil, nil, nil, function(buf)
		controls.save.enabled = (controls.dat.buf:match("%S") or controls.ggpk.buf:match("%S")) and buf:match("%S")
	end)
	controls.ggpkLabel = new("LabelControl", nil, 0, 40, 0, 16, "^7GGPK/Steam PoE path:")
	controls.ggpk = new("EditControl", {"TOP",controls.ggpkLabel,"TOP"}, 0, 20, 350, 20, datSource.ggpkPath, nil, nil, nil, function(buf)
		controls.save.enabled = (buf:match("%S") or controls.dat.buf:match("%S")) and controls.label.buf:match("%S") and controls.spec.buf:match("%S")
	end)
	controls.datLabel = new("LabelControl", {"TOP",controls.ggpk,"TOP"}, 0, 22, 0, 16, "^7DAT File location:")
	controls.dat = new("EditControl", {"TOP",controls.datLabel,"TOP"}, 0, 20, 350, 20, datSource.datFilePath, nil, nil, nil, function(buf)
		controls.save.enabled = (buf:match("%S") or controls.ggpk.buf:match("%S")) and controls.label.buf:match("%S") and controls.spec.buf:match("%S")
	end)
	controls.specLabel = new("LabelControl", {"TOP",controls.dat,"TOP"}, 0, 22, 0, 16, "^7Spec File location:")
	controls.spec = new("EditControl", {"TOP",controls.specLabel,"TOP"}, 0, 20, 350, 20, datSource.spec or "spec.lua", nil, nil, nil, function(buf)
		controls.save.enabled = (controls.dat.buf:match("%S") or controls.ggpk.buf:match("%S")) and controls.label.buf:match("%S") and buf:match("%S")
	end)
	controls.save = new("ButtonControl", {"TOP",controls.spec,"TOP"}, -45, 22, 80, 20, "Save", function()
		datSource.label = controls.label.buf
		datSource.ggpkPath = controls.ggpk.buf or ""
		datSource.datFilePath = controls.dat.buf or ""
		datSource.spec = controls.spec.buf
		if newSource then
			table.insert(self.list, datSource)
			self.selIndex = #self.list
			self.selValue = datSource
		end
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", {"TOP",controls.spec,"TOP"}, 45, 22, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 200, datSource[1] and "Edit DAT Source" or "New DAT Source", controls, "save", "edit")
end

function GGPKSourceListClass:OnSelDelete(index)
	if #self.list > 1 then
		table.remove(self.list, index)
		self.selIndex = nil
		self.selValue = nil
	end
end

function GGPKSourceListClass:GetRowValue(column, index, datSource)
	if column == 1 then
		return "^7"..datSource.label
	elseif column == 2 then
		return "^7"..datSource.spec
	end
end

function GGPKSourceListClass:OnSelClick(index, datSource, doubleClick)
	self.selIndex = index
	self.selValue = datSource
	if doubleClick then
		self:EditDATSource(datSource)
	end
end
