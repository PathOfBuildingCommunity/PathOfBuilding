---@meta

---@alias BustedCallback fun(...: any)

---@class BustedAssertion
---@operator call(any...): any
---@field are BustedAssertion
---@field are_not BustedAssertion
---@field has BustedAssertion
---@field has_no BustedAssertion
---@field is BustedAssertion
---@field is_not BustedAssertion
---@field was BustedAssertion
---@field was_not BustedAssertion
---@field [string] fun(...: any): BustedAssertion
assert = { }

---@param name string
---@param callback BustedCallback
function describe(name, callback) end

---@param name string
---@param callback BustedCallback
function it(name, callback) end

---@param name string
---@param callback BustedCallback
function expose(name, callback) end

---@param name string
---@param callback? BustedCallback
function pending(name, callback) end

---@param callback BustedCallback
function before_each(callback) end

---@param callback BustedCallback
function after_each(callback) end

---@param callback BustedCallback
function before_all(callback) end

---@param callback BustedCallback
function after_all(callback) end

---@param callback BustedCallback
function setup(callback) end

---@param callback BustedCallback
function teardown(callback) end

---@param callback BustedCallback
function finally(callback) end
