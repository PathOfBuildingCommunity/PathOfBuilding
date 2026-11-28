-- Preserve PoB's saved display stats and append scalar calculation results.
-- Nested tables include live actor, item and skill objects with cycles.
return function(xml, output, element)
	local saved, extra = {}, {}
	for _, child in ipairs(xml) do
		if child.elem == element then saved[child.attrib.stat] = true end
	end
	for key, value in pairs(output) do
		if type(key) == "string" and not saved[key] and (type(value) == "number" or type(value) == "boolean") then
			extra[#extra + 1] = key
		end
	end
	table.sort(extra)
	for _, key in ipairs(extra) do
		xml[#xml + 1] = { elem = element, attrib = { stat = key, value = tostring(output[key]) } }
	end
end
