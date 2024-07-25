-- Path of Building
--
-- Class: ArchivesListControl
-- Archives list control.
--

local t_insert = table.insert
local dkjson = require "dkjson"

local archivesUrl = 'https://pobarchives.com'

local PoBArchivesProviderClass = newClass("PoBArchivesProvider", "ExtBuildListProvider",
	function(self, mode)
		if mode == "builds" then
			self.ExtBuildListProvider({"Trending", "Latest"})
		else
			self.ExtBuildListProvider({"Similar Builds"})
		end
		self.buildList = {}
		self.mode = mode
	end
)

function PoBArchivesProviderClass:GetApiUrl()
	if self.importCode then
		return archivesUrl .. '/api/' .. 'recommendations'
	else
		return archivesUrl .. '/api/builds?q=' .. string.lower(self.activeList)
	end
end

function PoBArchivesProviderClass:GetPageUrl()
	local buildsPath = '/builds'
	if self.activeList == "Latest" then
		return archivesUrl .. buildsPath .. '/yenTGNDb'
	end
	if self.activeList == "Trending" then
		return archivesUrl .. buildsPath .. '/7U8QXU8m?sort=popularity'
	end
	-- TODO extract id and page
	if self.mode == "similar" then
		-- return archivesUrl .. buildsPath .. '/?similar=' .. self.importCode
		return nil
	end

	return nil
end
function PoBArchivesProviderClass:GetRecommendations(buildCode, postURL)
	local id = LaunchSubScript([[
			local code, connectionProtocol, proxyURL = ...
			local curl = require("lcurl.safe")
			local page = ""
			local easy = curl.easy()
			easy:setopt_url(']]..postURL..[[')
			easy:setopt(curl.OPT_POST, true)
			easy:setopt(curl.OPT_USERAGENT, "Path of Building/]]..launch.versionNumber..[[")
			easy:setopt(curl.OPT_POSTFIELDS, ']].."importCode="..[['..code)
			easy:setopt(curl.OPT_ACCEPT_ENCODING, "")
			if connectionProtocol then
				easy:setopt(curl.OPT_IPRESOLVE, connectionProtocol)
			end
			if proxyURL then
				easy:setopt(curl.OPT_PROXY, proxyURL)
			end
			easy:setopt_writefunction(function(data)
				page = page..data
				return true
			end)
			easy:perform()
			local res = easy:getinfo_response_code()
			easy:close()
			return page, res
	]], "", "", buildCode, launch.connectionProtocol, launch.proxyURL)

	if id then
		launch:RegisterSubScript(id, function(response, errMsg)
			if errMsg == 200 then
				self.statusMsg = nil
				self:ParseBuilds(response)
				return
			else
				self.statusMsg = "Error while fetching similar builds: " .. errMsg
				return
			end
		end)
	end

end

function PoBArchivesProviderClass:ParseBuilds(message)
	local obj = dkjson.decode(message)
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
		if value.build_info.class ~= "None" then
			build.class = value.build_info.class
		end
		build.previewLink = archivesUrl .. "/build/" .. value.build_info.short_uuid
		build.buildLink = value.build_info.build_link
		build.ehp = value.stats.TotalEHP
		build.life = value.stats.LifeUnreserved
		build.es = value.stats.EnergyShield
		build.dps = value.fullDPS
		build.version = value.tree and value.tree.version

		if value.similarity_score then
			build.metadata = {
				{key="Match Score", value=value.similarity_score},
			}
		end
		-- build.score = value.similarity_score
		t_insert(self.buildList, build)
	end
end

function PoBArchivesProviderClass:GetBuilds()
	self.statusMsg = "Loading.."
	wipeTable(self.buildList)
	self.contentHeight = nil


	if self.mode == 'similar' then
		self:GetRecommendations(self.importCode,self:GetApiUrl())
		return
	else
		launch:DownloadPage(self:GetApiUrl(), function(response, errMsg)
			if errMsg then
				self.statusMsg = errMsg
				return
			end

			self:ParseBuilds(response.body)

			self.statusMsg = nil
		end, {})
	end
end
