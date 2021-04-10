--
-- Basic Lua XML Handling
-- Based on code by Roberto Ierusalimschy
--

local t_insert, t_remove = table.insert, table.remove


local function decodeContent(content)
	-- Decode content, replacing entities
	local entTbl = {["lt"] = "<", ["gt"] = ">", ["amp"] = "&", ["apos"] = "'", ["quot"] = '"'}
	return (content:gsub("&(.-);", function (ent)
		return entTbl[ent] or ""
	end))
end

local function encodeContent(text)
	-- Encode content, escaping forbidden characters
	local subTbl = {["<"] = "lt", [">"] = "gt", ["&"] = "amp", ["'"] = "apos", ['"'] = "quot"}
	return (text:gsub("[<>&'\"]", function (chr)
		return "&" .. subTbl[chr] .. ";"
	end))
end

local function parseAttribs(str)
	local attrib = { }
	str:gsub("(%w+)=([\"'])(.-)%2", function (key, _, val)
		attrib[key] = decodeContent(val)
	end)
	return attrib
end

local xml = { }

function xml.ParseXML(str)
	str = str:gsub("<!%-%-.-%-%->", "") -- Strip comments
	local top = { }
	local stack = {top}
	local i = 1
	local content, cdata, ie, cs, elem, attrib, ce
	while true do
		content, cdata, ie = str:match("^%s*([^<]-)%s*<!%[CDATA%[(.-)%]%]>()", i)
		if content then
			-- Found CDATA section
			if content:find("%S") then
				t_insert(top, decodeContent(content))
			end
			if cdata:find("%S") then
				t_insert(top, cdata)
			end
		else
			content, cs, elem, attrib, ce, ie = str:match("^%s*([^<]-)%s*<([%?/]?)([%w:]+)(.-)([%?/]?)>()", i)
			if not content then
				-- No more tags found
				break
			end
			if content:find("%S") then
				t_insert(top, decodeContent(content))
			end
			if cs == "?" or ce == "?" then
				-- Processing instruction, ignore
			elseif ce == "/" then
				-- Empty element
				t_insert(top, {elem = elem, empty = true, attrib = parseAttribs(attrib)})
			elseif cs == "" then
				-- Start tag
				top = {elem = elem, attrib = parseAttribs(attrib)}
				t_insert(stack, top)
			else
				-- End tag
				if #stack == 1 then
					return nil, "nothing to close with '"..elem.."'"
				end
				if top.elem ~= elem then
					return nil, "trying to close <"..top.elem.."> with '"..elem.."'"
				end
				if #top == 0 then
					top.empty = true
				end
				local closed = t_remove(stack)
				top = stack[#stack]
				t_insert(top, closed)
			end
		end
		i = ie
	end
	if #stack > 1 then
		return nil, "unclosed element '"..stack[#stack].elem.."'"
	end
	local content = str:match("^%s*(.-)%s*$", i)
	if content:find("%S") then
		t_insert(stack[1], decodeContent(content))
	end
	return stack[1]
end

function xml.LoadXMLFile(fileName)
	local fileHnd, errMsg = io.open(fileName, "r")
	if not fileHnd then
		return nil, errMsg
	end
	local fileText = fileHnd:read("*a")
	fileHnd:close()
	return xml.ParseXML(fileText)
end

local function composeNode(frag, node, lvl)
	if type(node.elem) ~= "string" then
		return "invalid xml tree (missing element name)"
	end
	t_insert(frag, string.rep("\t", lvl))
	t_insert(frag, '<')
	t_insert(frag, node.elem)
	if node.attrib then
		for key, val in pairs(node.attrib) do
			if val then
				if type(key) ~= "string" then
					return "invalid xml tree (attribute name in <"..node.elem.."> is not a string)"
				elseif type(val) ~= "string" then
					return "invalid xml tree (value for attribute '"..key.."' in <"..node.elem.."> is not a string)"
				end
				t_insert(frag, ' ')
				t_insert(frag, key)
				t_insert(frag, '="')
				t_insert(frag, encodeContent(val))
				t_insert(frag, '"')
			end
		end
	end
	if not node[1] then
		t_insert(frag, '/>\n')
		return
	end
	t_insert(frag, '>\n')
	for _, n in ipairs(node) do
		if type(n) == "table" then
			local errMsg = composeNode(frag, n, lvl + 1)
			if errMsg then
				return errMsg
			end
		elseif type(n) == "string" then
			t_insert(frag, string.rep("\t", lvl + 1))
			t_insert(frag, encodeContent(n))
			t_insert(frag, '\n')
		else
			return "invalid xml tree (child of <"..node.elem.."> is not table or string)"
		end
	end
	t_insert(frag, string.rep("\t", lvl))
	t_insert(frag, '</')
	t_insert(frag, node.elem)
	t_insert(frag, '>\n')
end

function xml.ComposeXML(rootNode)
	if type(rootNode) ~= "table" then
		return nil, "invalid xml tree"
	end
	local frag = { '<?xml version="1.0" encoding="UTF-8"?>\n' }
	local errMsg = composeNode(frag, rootNode, 0)
	if errMsg then
		return nil, errMsg
	else
		return table.concat(frag)
	end
end

function xml.SaveXMLFile(rootNode, fileName)
	local text, errMsg = xml.ComposeXML(rootNode)
	if not text then
		return nil, errMsg
	end
	local fileHnd, errMsg = io.open(fileName, "w+")
	if not fileHnd then
		return nil, errMsg
	end
	fileHnd:write(text)
	fileHnd:close()
	return true
end

return xml