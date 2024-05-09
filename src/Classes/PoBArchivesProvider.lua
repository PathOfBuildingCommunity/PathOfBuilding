-- Path of Building
--
-- Class: ArchivesListControl
-- Archives list control.
--

local t_insert = table.insert
local dkjson = require "dkjson"

local archivesUrl = 'https://pobarchives.com'

local PoBArchivesProviderClass = newClass("PoBArchivesProvider", "ExtBuildListProvider",
	function(self)
		self.ExtBuildListProvider({"Latest", "Trending"})
		self.buildList = {}
	end
)

function PoBArchivesProviderClass:GetApiUrl()
	local apiPath = '/api/builds'
	return archivesUrl .. apiPath .. '?q=' .. string.lower(self.activeList)
end

function PoBArchivesProviderClass:GetPageUrl()
	local buildsPath = '/builds'
	if self.activeList == "Latest" then
		return archivesUrl .. buildsPath .. '/yenTGNDb'
	end
	if self.activeList == "Trending" then
		return archivesUrl .. buildsPath .. '/7U8QXU8m?sort=popularity'
	end
	if self.activeList == "similar" then
		return archivesUrl .. buildsPath .. '/?similar=' .. self.similarTo
	end

	return nil
end

function PoBArchivesProviderClass:GetBuilds()
	self.statusMsg = "Loading.."
	wipeTable(self.buildList)
	self.contentHeight = nil
	launch:DownloadPage(self:GetApiUrl(), function(response, errMsg)
		if errMsg then
			self.statusMsg = errMsg
			return
		end

		local obj = dkjson.decode(response.body)
		if not obj or not obj.builds or next(obj.builds) == nil then
			self.statusMsg = "No builds found."
			return
		end


		for _, value in pairs(obj.builds) do
			local build = {}
			build.buildName = value.build_info.title
			build.author = value.build_info.author
			build.mainSkill = value.build_info.mainSkill
			if value.build_info.ascendancy ~= "None" then
				build.ascendancy = value.build_info.ascendancy
			end
			build.previewLink = "https://pobarchives.com/build/" .. value.build_info.short_uuid
			build.buildLink = value.build_info.build_link
			build.ehp = value.stats.TotalEHP
			build.life = value.stats.LifeUnreserved
			build.es = value.stats.EnergyShield
			build.dps = value.fullDPS
			t_insert(self.buildList, build)
		end

		self.statusMsg = nil
	end, {})
end
