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

--- APISourceInfo is the configurated data for a source from the enduser
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
--- Save this to disk for temporary local caching if required/desired
---@class BuildInfoCache
---@field pobdata string
---@field name string
---@field lastModified integer
---@field buildId string
---@field sourceName string

--- API Capabilities returned by the source or defaulted to APISourceInfo
---@class APICapabilities
---@field name string
---@field fallbackVersion integer
---@field endpointType EndpointType
---@field baseAPIPath? string
---@field league_filter? boolean
---@field gem_filter? boolean

--- This primarily exists for the lua language server
---@param buildInfo BuildInfo
---@param source APICapabilities
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
---@field buildList table<string,BuildInfoCache>
---@field apiCapabilities table<string, APICapabilities>
local APIContractBuilds = newClass("APIContractBuilds",
	function(self)
		self.buildList = {}
		self.apiCapabilities = {}
	end
)

-- Switch case for GET Endpoint for Builds
local getBuildVersions = {
	[0] = function(...) return APIContractBuilds:GetBuildsVersion1(...) end,
}

--- Gets the builds from the source
---@param source APISourceInfo
function APIContractBuilds:GetBuilds(source)
	getBuildVersions[source.fallbackVersion](source.endpointType)
end

---@param source APISourceInfo
function APIContractBuilds:UpdateAPICapabilities(source)
	-- TODO: Which features are supported?
	-- What is the latest version that is supported?
	-- Which endpoints are supported
	-- Is Querying supported? (CSV won't support this probably)

	if source.endpointType ~= EndpointType.REST then
		return
	end

	launch:DownloadPage(source.baseUrl + "/.well-known/pathofbuilding",
		function(...) return APIContractBuilds:APICapabilitiesCallback(source, ...) end, {})
end

--- Updates the API capabilities for the source
---@param response table
---@param errMsg any
---@param source APISourceInfo
function APIContractBuilds:APICapabilitiesCallback(source, response, errMsg)
	local parsedResponse = dkjson.decode(response.body)
	---@cast parsedResponse APICapabilities
	if errMsg or not parsedResponse.baseAPIPath then
		parsedResponse.baseAPIPath = source.baseUrl
	end
	parsedResponse.name = source.name
	parsedResponse.fallbackVersion = source.fallbackVersion
	parsedResponse.endpointType = source.endpointType

	self.apiCapabilities[source.name] = parsedResponse
end

--- Adds/Updates Builds for the source based on version 1
---@param response table
---@param errMsg any
---@param source APICapabilities
function APIContractBuilds:BuildsVersion1Callback(source, response, errMsg)
	local parsedResponse = dkjson.decode(response.body)
	---@cast parsedResponse BuildInfo[]
	for _, build in ipairs(parsedResponse) do
		-- source and buildId will be used as a caching key
		-- to avoid buildId collissions
		self.buildList[common.sha1(source.name + "-" + build.buildId)] = buildInfoToCache(build, source)
	end
end

--- Version 1 of the API Contract for Builds
---@param source APICapabilities
function APIContractBuilds:GetBuildsVersion1(source)
	if source.endpointType == EndpointType.CSV then
		-- TODO: Implement CSV Parsing and Format
		return
	end

	launch:DownloadPage(source.baseAPIPath + "/v1/builds", function(...)
		self:BuildsVersion1Callback(source, ...)
	end, {})
end
