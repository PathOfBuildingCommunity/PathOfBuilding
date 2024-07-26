-- Path of Building
--
-- Class: API Contract Builds
-- API contract proposal for builds
--

local dkjson = require "dkjson"


---@enum EndpointType
local EndpointType = {
	REST = 0,
	CSV = 1
}

--example for REST vs CSV
-- REST:
-- {"baseUrl": "https://mypoebuilds.gg/pob-api/", "name": "MyPoEBuilds REST", "endpointType": 0, "fallbackVersion": 1}
-- baseUrl meaning the actual baseUrl
-- CSV:
-- {"baseUrl": "https://mypoebuilds.gg/pob-builds.csv", "name": "MyPoEBuilds CSV", "endpointType": 1, "fallbackVersion": 1}
-- baseUrl means here the full URL to the actual file or endpoint that returns a CSV formatted file from a GET endpoint

--- This is the required information from the enduser
---@class APISourceInfo
---@field name string
---@field baseUrl string
---@field endpointType EndpointType
---@field fallbackVersion integer

--- This data should be returned by the source
---@class BuildInfo
---@field pobdata string
---@field name string
---@field lastModified integer
---@field buildId string

--- This data is saved internally for caching
---@class BuildInfoCache
---@field pobdata string
---@field name string
---@field lastModified integer
---@field buildId string
---@field sourceName string

---This primarily exists for the lua language server
---@param buildInfo BuildInfo
---@param source APISourceInfo
---@return BuildInfoCache
local function buildInfoToCache(buildInfo, source)
	return {
		pobdata = buildInfo.pobdata,
		name = buildInfo.name,
		lastModified = buildInfo.lastModified,
		buildId = buildInfo.buildId,
		sourceName = source.name
	}
end

---@class APIContractBuilds
---@field buildList BuildInfoCache[]
local APIContractBuilds = newClass("APIContractBuilds",
	function(self)
		self.buildList = {}
	end
)

-- Switch case for GET Endpoint for Builds
local getBuildVersions = {
	[0] = function(...) return APIContractBuilds:GetBuildsVersion1(...) end,
}

---comments
---@param path string
---@param source APISourceInfo
function APIContractBuilds:GetBuilds(path, source)
	local builds = getBuildVersions[source.fallbackVersion](path, source.endpointType)
end

---@param source APISourceInfo
function APIContractBuilds:GetAPICapabilities(source)
	-- TODO: Which features are supported?
	-- What is the latest version that is supported?
	-- Which endpoints are supported
	-- Is Querying supported? (CSV won't support this probably)
end

---@param response table | BuildInfo[]
---@param errMsg any
---@param source APISourceInfo
function APIContractBuilds:BuildsVersion1Callback(source, response, errMsg)
	for _, build in ipairs(response) do
		-- source and buildId will be used as a caching key
		-- to avoid buildId collissions
		self.buildList[common.sha1(source.name + "-" + build.buildId)] = buildInfoToCache(build, source)
	end
end

---Version 1 of the API Contract for Builds
---@param path string
---@param source APISourceInfo
function APIContractBuilds:GetBuildsVersion1(path, source)
	if source.endpointType == EndpointType.REST then
		launch:DownloadPage(source.baseUrl + path, function(...)
			self:BuildsVersion1Callback(source, ...)
		end, {})
	end
end
