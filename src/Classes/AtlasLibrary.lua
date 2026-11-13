local ipairs = ipairs
local t_insert = table.insert

local AtlasLibraryClass = newClass("AtlasLibrary")

function AtlasLibraryClass:AtlasLibrary(path)
	self.path = path
	self.specList = { }
	self.activeSpec = 1
	self:Load()
	if not self.specList[1] then
		t_insert(self.specList, new("AtlasSpec"):AtlasSpec(latestAtlasTreeVersion))
	end
	self.activeSpec = math.max(1, math.min(self.activeSpec, #self.specList))
	self.modFlag = false
	return self
end

function AtlasLibraryClass:Load()
	if not self.path then
		return
	end
	local file = io.open(self.path, "r")
	if not file then
		return
	end
	file:close()
	local xml, errMsg = common.xml.LoadXMLFile(self.path)
	if not xml or not xml[1] then
		ConPrintf("Failed to read atlas trees from '%s': %s", self.path, tostring(errMsg))
		return
	end
	for _, node in ipairs(xml[1]) do
		if type(node) == "table" and node.elem == "Spec" then
			local spec = new("AtlasSpec"):AtlasSpec(latestAtlasTreeVersion)
			spec:Load(node)
			t_insert(self.specList, spec)
		end
	end
	self.activeSpec = tonumber(xml[1].attrib and xml[1].attrib.activeSpec) or 1
end

function AtlasLibraryClass:Save()
	if not self.path then
		return false
	end
	local root = { elem = "AtlasTrees", attrib = { activeSpec = tostring(self.activeSpec) } }
	for _, spec in ipairs(self.specList) do
		local child = { elem = "Spec" }
		spec:Save(child)
		t_insert(root, child)
	end
	local ok, errMsg = common.xml.SaveXMLFile(root, self.path)
	if not ok and not self.reportedSaveError then
		self.reportedSaveError = true
		ConPrintf("Failed to save atlas trees to '%s': %s", self.path, tostring(errMsg))
	end
	return ok and true or false
end

function AtlasLibraryClass:IsModified()
	if self.modFlag then
		return true
	end
	for _, spec in ipairs(self.specList) do
		if spec.modFlag then
			return true
		end
	end
	return false
end

function AtlasLibraryClass:SaveIfModified()
	if not self:IsModified() then
		return
	end
	self.modFlag = false
	for _, spec in ipairs(self.specList) do
		spec.modFlag = false
	end
	self:Save()
end

local function specKey(spec)
	return spec.title .. "|" .. spec.treeVersion .. "|" .. table.concat(spec:GetAllocatedIds(), ",")
end

function AtlasLibraryClass:ImportSpecs(xml)
	local known = { }
	for _, spec in ipairs(self.specList) do
		known[specKey(spec)] = true
	end
	local onlyDefault = #self.specList == 1 and self.specList[1]:CountAllocNodes() == 0 and self.specList[1].title == "Default"
	local imported = 0
	for _, node in ipairs(xml) do
		if type(node) == "table" and node.elem == "Spec" then
			local spec = new("AtlasSpec"):AtlasSpec(latestAtlasTreeVersion)
			spec:Load(node)
			local key = specKey(spec)
			if not known[key] and spec:CountAllocNodes() > 0 then
				known[key] = true
				if onlyDefault then
					self.specList[1] = spec
					onlyDefault = false
				else
					t_insert(self.specList, spec)
				end
				imported = imported + 1
			end
		end
	end
	if imported > 0 then
		self.modFlag = true
	end
	return imported
end
