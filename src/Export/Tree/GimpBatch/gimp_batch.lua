local module = { }

local function schemePath(path)
	return path:gsub("\\", "/"):gsub('"', '\\"')
end

local function gimpExecutable()
	local programFiles = os.getenv("ProgramFiles")
	local installed = programFiles and programFiles .. "\\GIMP 3\\bin\\gimp-console-3.exe"
	local file = installed and io.open(installed, "rb")
	if file then
		file:close()
		return installed
	end
	return "gimp-console-3.exe"
end

-- Put all sprite operations in one script so GIMP only needs to start once.
function module.new_batch(scriptPath, dependencies)
	local batch = {
		path = scriptPath,
		script = assert(io.open(scriptPath, "w")),
	}
	for _, dependency in ipairs(dependencies) do
		batch.script:write(string.format('(load "%s")\n', schemePath(dependency)))
	end
	return batch
end

-- GIMP does the same PNG sprite composition used by the PoB 2 exporter. Each
-- entry contains the source crop followed by its position and size in the atlas.
function module.combine_images_to_sprite(batch, sheetData, outputPath, saturation)
	local coords = { }
	for _, entry in ipairs(sheetData.coords) do
		coords[#coords + 1] = string.format(
			'("%s" %d %d %d %d %d %d %d %d)',
			schemePath(entry.file),
			entry.sourceX, entry.sourceY, entry.sourceWidth, entry.sourceHeight,
			entry.x, entry.y, entry.width, entry.height
		)
	end

	batch.script:write(string.format(
		'(combine-images-into-sprite-sheet "%s" %d %d %d \'(%s))\n',
		schemePath(outputPath .. sheetData.filename), sheetData.w, sheetData.h, saturation, table.concat(coords, " ")
	))
end

-- The game stores every orbit in one image. This uses the shared centre and
-- radii of those curves to produce the six orbit images PoB renders.
function module.extract_abyss_lines(batch, sources, temporaryPath, outputPath)
	for _, source in ipairs(sources) do
		local sourceFile = source.file
		if source.effect then
			sourceFile = temporaryPath .. "abyss-preview.png"
			batch.script:write(string.format(
				'(make-abyss-preview "%s" "%s" "%s")\n',
				schemePath(source.file), schemePath(source.effect), schemePath(sourceFile)
			))
		end
		batch.script:write(string.format(
			'(extract-abyss-lines "%s" "%s" "%s" "%s" %d)\n',
			schemePath(sourceFile), schemePath(temporaryPath), schemePath(outputPath),
			source.state, source.state == "active" and 1 or 0
		))
	end
end

function module.run_batch(batch)
	batch.script:close()
	local command = string.format(
		'cmd /c ""%s" -n -i -s -c --batch-interpreter=plug-in-script-fu-eval -b "(load \\\"%s\\\")" --quit"',
		gimpExecutable(), schemePath(batch.path)
	)
	return os.execute(command)
end

return module
