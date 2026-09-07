-- Run this from the exporter's Scripts screen after selecting the current game data.
-- Lua builds the sheet data and GIMP writes PNGs using the same structure as PoB 2.

local gimpBatch = require("Tree/GimpBatch/gimp_batch")

local function round(value)
	return math.floor(value + 0.5)
end

-- The source UI images are made for the game's larger passive-tree canvas.
local treeArtScale = 0.3835

local function addFile(files, path)
	if path and path ~= "" then
		files[path] = true
	end
end

-- Keep images of the same height on one row. This is the layout used by the
-- PoB 2 PNG exporter and keeps coordinates stable when new rows are added.
local function packEntries(entries, maximumWidth)
	table.sort(entries, function(a, b)
		if a.height ~= b.height then
			return a.height < b.height
		elseif a.width ~= b.width then
			return a.width < b.width
		end
		return a.name:lower() < b.name:lower()
	end)

	local x, y, rowHeight, usedWidth = 0, 0, 0, 0
	local coords = { }
	for _, entry in ipairs(entries) do
		if x > 0 and (x + entry.width > maximumWidth or entry.height ~= rowHeight) then
			x = 0
			y = y + rowHeight
			rowHeight = 0
		end
		entry.x = x
		entry.y = y
		coords[entry.name] = entry
		x = x + entry.width
		rowHeight = math.max(rowHeight, entry.height)
		usedWidth = math.max(usedWidth, x)
	end
	return coords, usedWidth, y + rowHeight
end

local function writeSheet(output, name, filename, coords, names)
	output:write(string.format('\t["%s"] = {{\n', name))
	output:write(string.format('\t\t["filename"] = "%s",\n', filename))
	output:write('\t\t["coords"] = {\n')
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	for _, assetName in ipairs(names) do
		local coord = coords[assetName]
		output:write(string.format(
			'\t\t\t["%s"] = { ["x"] = %d, ["y"] = %d, ["w"] = %d, ["h"] = %d },\n',
			assetName, coord.x, coord.y, coord.width, coord.height
		))
	end
	output:write('\t\t},\n\t}},\n')
end

main.ggpk:ExtractList({ "art/uiimages1.txt" }, { })
local uiImages = { }
for line in convertUTF16to8(getFile("art/uiimages1.txt")):gmatch("[^\r\n]+") do
	local name, path, x, y, right, bottom = line:match(
		'^"([^"]+)"%s+"([^"]+)"%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)'
	)
	if name then
		uiImages[name:lower()] = {
			path = path,
			x = tonumber(x),
			y = tonumber(y),
			width = tonumber(right) - tonumber(x) + 1,
			height = tonumber(bottom) - tonumber(y) + 1,
		}
	end
end

local alternateArt
for row in dat("AlternateTreeArt"):Rows() do
	if row.TreeVersion and row.TreeVersion.Id:match("^Abyss") then
		if not alternateArt then
			alternateArt = row
		else
			-- All current Abyss jewels use one art set. Stop the export if a future
			-- jewel needs another set instead of silently giving it the wrong art.
			assert(row.ConnectionArt.Id == alternateArt.ConnectionArt.Id
				and row.KeystoneFrameArt.Id == alternateArt.KeystoneFrameArt.Id
				and row.NotableFrameArt.Id == alternateArt.NotableFrameArt.Id
				and row.AscendancyFrameArt.Id == alternateArt.AscendancyFrameArt.Id,
				"Abyss alternate tree art sets do not match")
		end
	end
end
assert(alternateArt, "Abyss alternate tree art was not found")

local files = { }
local iconEntries = { }
local iconSections = { normal = { }, notable = { }, keystone = { } }
local iconSizes = { normal = 27, notable = 38, keystone = 64 }
local seenIcons = { }
for passive in dat("AlternatePassiveSkills"):Rows() do
	local icon = passive.DDSIcon
	if icon and icon ~= "" and not seenIcons[icon] then
		local section = "normal"
		if isValueInTable(passive.PassiveType, 4) then
			section = "keystone"
		elseif isValueInTable(passive.PassiveType, 3) or isValueInTable(passive.PassiveType, 5) then
			section = "notable"
		end
		seenIcons[icon] = true
		iconSections[section][#iconSections[section] + 1] = icon
		iconEntries[#iconEntries + 1] = {
			name = icon,
			file = main.ggpk.oozPath .. icon:lower(),
			width = iconSizes[section],
			height = iconSizes[section],
		}
		addFile(files, icon)
	end
end

local frameEntries = { }
local frameGroups = {
	{ art = alternateArt.NotableFrameArt, prefix = "AbyssNotableFrame" },
	{ art = alternateArt.KeystoneFrameArt, prefix = "AbyssKeystoneFrame" },
	{ art = alternateArt.AscendancyFrameArt, prefix = "AbyssAscendancyFrame" },
}
local frameStates = {
	{ column = "Normal", suffix = "Unallocated" },
	{ column = "CanAllocate", suffix = "CanAllocate" },
	{ column = "Active", suffix = "Allocated" },
}
for _, group in ipairs(frameGroups) do
	for _, state in ipairs(frameStates) do
		local image = assert(uiImages[group.art[state.column]:lower()], "Missing UIImages row for Abyss frame")
		frameEntries[#frameEntries + 1] = {
			name = group.prefix .. state.suffix,
			file = main.ggpk.oozPath .. image.path:lower(),
			sourceX = image.x,
			sourceY = image.y,
			sourceWidth = image.width,
			sourceHeight = image.height,
			width = round(image.width * treeArtScale),
			height = round(image.height * treeArtScale),
		}
		addFile(files, image.path)
	end
end

local connectionArt = alternateArt.ConnectionArt
local connectionSources = {
	{ state = "normal", file = connectionArt.Normal },
	-- Active is an effect mask. The game colors it gold over the normal curve
	-- while previewing a path; it is not itself a displayed connector texture.
	{ state = "intermediate", file = connectionArt.Normal, effect = connectionArt.Active },
	-- Despite the column name, Mask contains the completed green curve art.
	{ state = "active", file = connectionArt.Mask },
}
for _, source in ipairs(connectionSources) do
	addFile(files, source.file)
	addFile(files, source.effect)
	source.file = main.ggpk.oozPath .. source.file:lower()
	if source.effect then
		source.effect = main.ggpk.oozPath .. source.effect:lower()
	end
end

local filesToExtract = { }
for file in pairs(files) do
	filesToExtract[#filesToExtract + 1] = file
end
table.sort(filesToExtract)
main.ggpk:ExtractList(filesToExtract, { })

for _, entry in ipairs(iconEntries) do
	local file = assert(io.open(entry.file, "rb"))
	file:seek("set", 12)
	local dimensions = file:read(8)
	file:close()
	entry.sourceWidth, entry.sourceHeight = bytesToUInt(dimensions, 5), bytesToUInt(dimensions, 1)
	entry.sourceX, entry.sourceY = 0, 0
end

local outputPath = GetScriptPath() .. "/../TreeData/legion/"
local temporaryPath = main.ggpk.oozPath .. "data/"
local iconCoords, iconWidth, iconHeight = packEntries(iconEntries, 512)
local combineImagesScript = GetScriptPath() .. "/Tree/GimpBatch/combine_images.scm"
local orbitSizes = {
	normal = { 33, 64, 130, 191, 256, 322 },
	intermediate = { 33, 64, 130, 191, 256, 322 },
	active = { 39, 70, 136, 197, 262, 329 },
}
for state, sizes in pairs(orbitSizes) do
	for orbit, size in ipairs(sizes) do
		frameEntries[#frameEntries + 1] = {
			name = "AbyssOrbit" .. orbit .. state:gsub("^%l", string.upper),
			file = temporaryPath .. "abyss-orbit" .. orbit .. "-" .. state .. ".png",
			sourceX = 0,
			sourceY = 0,
			sourceWidth = size,
			sourceHeight = size,
			width = size,
			height = size,
		}
	end
end
local artCoords, artWidth, artHeight = packEntries(frameEntries, 512)
local batch = gimpBatch.new_batch(temporaryPath .. "legion-sprites.scm", {
	combineImagesScript,
	GetScriptPath() .. "/Tree/GimpBatch/extract_abyss_lines.scm",
})
gimpBatch.combine_images_to_sprite(
	batch, { filename = "legion-active.png", w = iconWidth, h = iconHeight, coords = iconEntries }, outputPath, 100
)
gimpBatch.combine_images_to_sprite(
	batch, { filename = "legion-inactive.png", w = iconWidth, h = iconHeight, coords = iconEntries }, outputPath, 40
)
gimpBatch.extract_abyss_lines(batch, connectionSources, temporaryPath, outputPath)
gimpBatch.combine_images_to_sprite(
	batch, { filename = "legion-art.png", w = artWidth, h = artHeight, coords = frameEntries }, outputPath, 100
)
local result = gimpBatch.run_batch(batch)
assert(result == 0 or result == true, "GIMP failed to create the Legion sprite sheets")

local output = assert(io.open(outputPath .. "tree-legion.lua", "w"))
output:write("-- This file is automatically generated by Export/Scripts/legionSprites.lua.\n")
output:write("return {\n")
writeSheet(output, "keystoneActive", "legion-active.png", iconCoords, iconSections.keystone)
writeSheet(output, "keystoneInactive", "legion-inactive.png", iconCoords, iconSections.keystone)
writeSheet(output, "notableActive", "legion-active.png", iconCoords, iconSections.notable)
writeSheet(output, "notableInactive", "legion-inactive.png", iconCoords, iconSections.notable)
writeSheet(output, "normalActive", "legion-active.png", iconCoords, iconSections.normal)
writeSheet(output, "normalInactive", "legion-inactive.png", iconCoords, iconSections.normal)

local artNames = { }
for name in pairs(artCoords) do
	artNames[#artNames + 1] = name
end
output:write('\t["treeAssets"] = {\n')
output:write('\t\t{ ["filename"] = "legion-art.png", ["coords"] = {\n')
table.sort(artNames)
for _, name in ipairs(artNames) do
	local coord = artCoords[name]
	output:write(string.format(
		'\t\t\t["%s"] = { ["x"] = %d, ["y"] = %d, ["w"] = %d, ["h"] = %d },\n',
		name, coord.x, coord.y, coord.width, coord.height
	))
end
output:write('\t\t} },\n')
for _, state in ipairs({ "Normal", "Intermediate", "Active" }) do
	output:write(string.format(
		'\t\t{ ["filename"] = "abyss-line-connector-%s.png", ["coords"] = { ["AbyssLineConnector%s"] = { ["x"] = 0, ["y"] = 0, ["w"] = 368, ["h"] = 13 } } },\n',
		state:lower(), state
	))
end
output:write('\t},\n')
output:write("}\n")
output:close()

printf("Legion passive sprites and Abyss tree art exported.")
