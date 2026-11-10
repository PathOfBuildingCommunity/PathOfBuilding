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
---@field supportedVersion? integer
---@field baseAPIPath? string
---@field league_filter? boolean
---@field gem_filter? boolean

--- Build version 1 Filter option
---@class BuildVersion1Filter
---@field league string
---@field gem string

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

---@param t table
local function tableToQueryParams(t)
	if #t == 0 then
		return ""
	end
	local query = "?"
	for key, value in pairs(t) do
		if value then
			local tempValue = value
			if type(value) == "table" then
				tempValue = table.concat(value, ",")
			end
			query = query .. key .. "=" .. value .. "&"
		end
	end
	-- remove trailing &
	if #t > 0 then
		query = query:sub(1, #query - 1)
	end

	return query
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
	[1] = function(...) return APIContractBuilds:GetBuildsVersion1(...) end,
}
-- Switch case for GET Endpoint for Builds
local getBuildFilterVersions = {
	[1] = function(data) return APIContractBuilds:GetBuildVersion1Filter(data) end,
}

---@param data table
function APIContractBuilds:GetBuildVersion1Filter(data)
	return {
		league = data.league,
		gem = data.gem
	}
end

--- Gets the builds from the source
---@param source APICapabilities
---@param data table
function APIContractBuilds:GetBuilds(source, data)
	local getBuildsFunction = nil
	local getBuildsFilterFunction = nil
	if not source.supportedVersion then
		getBuildsFunction = getBuildVersions[source.fallbackVersion]
		getBuildsFilterFunction = getBuildFilterVersions[source.fallbackVersion]
	else
		getBuildsFunction = getBuildVersions[source.supportedVersion]
		getBuildsFilterFunction = getBuildFilterVersions[source.supportedVersion]
	end

	if getBuildsFunction and getBuildsFilterFunction then
		getBuildsFunction(source.endpointType, getBuildsFilterFunction(data), source)
	end
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
		self.buildList[common.sha1(source.name .. "-" .. build.buildId)] = buildInfoToCache(build, source)
	end
end

--- Version 1 of the API Contract for Builds
---@param source APICapabilities
---@param params BuildVersion1Filter
function APIContractBuilds:GetBuildsVersion1(source, params)
	if source.endpointType == EndpointType.CSV then
		-- TODO: Implement CSV Parsing and Format
		return
	end

	launch:DownloadPage(source.baseAPIPath .. "/v1/builds" .. tableToQueryParams(params), function(...)
		self:BuildsVersion1Callback(source, ...)
	end, {})
end
