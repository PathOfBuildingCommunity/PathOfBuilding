
json = require("dkjson")

function printf(...)
	print(string.format(...))
end

function loadDat(name)
	if _G[name] then
		return
	end
	printf("Loading '%s'...", name)
	local f = io.open(name..".json", "r")
	if not f then
		os.execute("pypoe_exporter dat json "..name..".json --files "..name..".dat")
		f = io.open(name..".json", "r")
	end
	local text = f:read("*a")
	f:close()
	local t = json.decode(text)[1]
	local headerMap = { }
	for i, header in pairs(t.header) do
		headerMap[header.name] = i
	end
	local rowMeta = {
		__index = function(self, index)
			if index == "print" then
				return function()
					for i, header in pairs(t.header) do
						printf("%s = %s", header.name, type(self[i]) == "table" and ("{ "..table.concat(self[i], ", ").." }") or self[i])
					end
				end
			else
				return rawget(self, headerMap[index])
			end
		end
	}
	_G[name] = setmetatable({ maxRow = #t.data - 1, headerMap = headerMap }, {
		__index = function(self, index)
			if type(index) == "number" then
				return setmetatable(t.data[index + 1], rowMeta)
			elseif headerMap[index] then
				return function(val)
					local col = headerMap[index]
					local out = { }
					for index, row in ipairs(t.data) do
						if type(row[col]) == "table" then
							for _, v in pairs(row[col]) do
								if v == val then
									table.insert(out, index - 1)
									break
								end
							end
						else
							if row[col] == val then
								table.insert(out, index - 1)
							end
						end
					end
					return out
				end
			end
		end
	})
	_G[name:gsub("%l","")] = _G[name]
end
