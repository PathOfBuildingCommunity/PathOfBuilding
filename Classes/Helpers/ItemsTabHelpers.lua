local itemTabHelpers = {}

local function createItemNameWithInfluences(item)
	local stringText = ""
	stringText = colorCodes[item.rarity]..item.name

	local influences = {}

	if item.corrupted then
		table.insert(influences, "^1Co")
	end

	if item.shaper then
		table.insert(influences, colorCodes.SHAPER.."S")
	end

	if item.elder then
		table.insert(influences, colorCodes.ELDER.."E")
	end

	if item.adjudicator then
		table.insert(influences, colorCodes.ADJUDICATOR.."W")
	end

	if item.basilisk then
		table.insert(influences, colorCodes.BASILISK.."H")
	end

	if item.crusader then
		table.insert(influences, colorCodes.CRUSADER.."Cr")
	end

	if item.eyrie then
		table.insert(influences, colorCodes.EYRIE.."R")
	end

	if (#influences > 0) then
		return stringText.." ("..table.concat(influences, colorCodes[item.rarity]..", ")..colorCodes[item.rarity]..")"
	end

    return stringText
end

itemTabHelpers.createItemNameWithInfluences = createItemNameWithInfluences

return itemTabHelpers
