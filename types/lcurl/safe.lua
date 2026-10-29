---@meta
---@module "lcurl.safe"

---@alias CurlWriteCallback fun(data: string): boolean|integer

---@class CurlError
---@field msg fun(self: CurlError): string

---@class CurlEasy
local easy = { }

---@param value string
---@return string
function easy:escape(value) end

---@param option integer
---@param value any
function easy:setopt(option, value) end

---@param url string
function easy:setopt_url(url) end

---@param userAgent string
function easy:setopt_useragent(userAgent) end

---@param callback CurlWriteCallback|any
function easy:setopt_writefunction(callback) end

---@param callback CurlWriteCallback
function easy:setopt_headerfunction(callback) end

---@return boolean? success
---@return CurlError? error
function easy:perform() end

function easy:close() end

---@param info integer
---@return any
function easy:getinfo(info) end

---@return integer?
function easy:getinfo_response_code() end

---@class Curl
---@field easy fun(): CurlEasy
---@field OPT_ACCEPT_ENCODING integer
---@field OPT_FOLLOWLOCATION integer
---@field OPT_HTTPHEADER integer
---@field OPT_IPRESOLVE integer
---@field OPT_POST integer
---@field OPT_POSTFIELDS integer
---@field OPT_PROXY integer
---@field OPT_SSL_VERIFYHOST integer
---@field OPT_SSL_VERIFYPEER integer
---@field OPT_USERAGENT integer
---@field INFO_REDIRECT_URL integer
---@field INFO_RESPONSE_CODE integer
---@field INFO_SIZE_DOWNLOAD integer
---@type Curl
local curl = { }

---@return CurlEasy
function curl.easy() end

return curl
