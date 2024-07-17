-- Path of Building
--
-- Class: ExtBuildListProvider
-- External Build List Provider
--
-- This is an abstract base class; derived classes can supply these properties and methods to implement their build list class:
-- .listTitles  [Titles of different API endpoints that provide builds, i.e Latest, Popular]
-- :GetBuilds  [Override this method to fill buildList with your API. Use .activeList to determine which tab is selected.]
-- :GetPageUrl [Return a page url that contains all builds in the current list. Use .activeList to determine which tab is selected.]
-- .buildList [Needs to be filled in :GetBuilds with current list. buildName and buildLink fields are required.]
-- .statusMsg [This can be used to print status message on the screen. Builds will not be listed if it has a value other than nil.]

local ExtBuildListProviderClass = newClass("ExtBuildListProvider",
	function(self, listTitles)
		self.listTitles = listTitles
		self.buildList = {}
		self.activeList = nil
		self.statusMsg = nil
	end
)

function ExtBuildListProviderClass:GetPageUrl()
	return nil
end

function ExtBuildListProviderClass:Activate()
	if self.listTitles and next(self.listTitles) then
		self:SetActiveList(self.listTitles[1])
	end
end

function ExtBuildListProviderClass:SetActiveList(activeList)
	if self.listTitles then
		for _, value in ipairs(self.listTitles) do
			if value == activeList then
				self.activeList = activeList
				self:GetBuilds()
			end
		end
	end
end

function ExtBuildListProviderClass:GetActiveList()
	return self.activeList
end

function ExtBuildListProviderClass:GetListTitles()
	return self.listTitles
end

function ExtBuildListProviderClass:GetActivePageUrl()
	return nil
end

function ExtBuildListProviderClass:GetBuilds()
	return {}
end

function ExtBuildListProviderClass:SetImportCode(importCode)
	self.importCode = importCode
end
