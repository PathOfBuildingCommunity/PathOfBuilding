-- Path of Building
--
-- Shared item socket editing controls for the Items and Skills tabs.
-- The owning tab supplies the item and commits changes to its own state.
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil

local socketDropList = {
	{ label = colorCodes.STRENGTH.."R", color = "R" },
	{ label = colorCodes.DEXTERITY.."G", color = "G" },
	{ label = colorCodes.INTELLIGENCE.."B", color = "B" },
	{ label = colorCodes.SCION.."W", color = "W" }
}

local socketColorDropList = {
	{ label = "" },
	{ label = colorCodes.SCION.."W", color = "W" },
	{ label = colorCodes.INTELLIGENCE.."B", color = "B" },
	{ label = colorCodes.DEXTERITY.."G", color = "G" },
	{ label = colorCodes.STRENGTH.."R", color = "R" }
}

local socketControls = { }

function socketControls.create(controls, anchor, getItem, onChange, includeBulkUpdate)
	local function editItem()
		local item = getItem()
		local previousSockets = item.sockets
		-- Item undo snapshots share nested tables until the next edit.
		item.sockets = copyTable(item.sockets)
		return item, previousSockets
	end
	local function commit(previousSockets)
		onChange(previousSockets)
		socketControls.update(controls, getItem())
	end
	for i = 1, 6 do
		local drop = new("DropDownControl"):DropDownControl({"LEFT",anchor,"RIGHT"}, {6 + (i-1) * 48, 0, 32, 20}, socketDropList, function(index, value)
			local item, previousSockets = editItem()
			item.sockets[i].color = value.color
			commit(previousSockets)
		end)
		drop.arrowSize = 6
		drop.shown = function()
			local item = getItem()
			return item.selectableSocketCount >= i and item.sockets[i] and item.sockets[i].color ~= "A"
		end
		controls["displayItemSocket"..i] = drop
		if i < 6 then
			local link = new("CheckBoxControl"):CheckBoxControl({"LEFT",drop,"RIGHT"}, {0, 0, 16}, nil, function(state)
				local item, previousSockets = editItem()
				if state and item.sockets[i].group ~= item.sockets[i+1].group then
					for s = i + 1, #item.sockets do
						item.sockets[s].group = item.sockets[s].group - 1
					end
				elseif not state and item.sockets[i].group == item.sockets[i+1].group then
					for s = i + 1, #item.sockets do
						item.sockets[s].group = item.sockets[s].group + 1
					end
				end
				commit(previousSockets)
			end)
			link.height = 20
			link.linkStyle = true
			link.shown = function()
				local item = getItem()
				return item.selectableSocketCount > i and item.sockets[i+1] and item.sockets[i+1].color ~= "A"
			end
			controls["displayItemLink"..i] = link
		end
	end
	controls.displayItemAddSocket = new("ButtonControl"):ButtonControl({"LEFT",anchor,"RIGHT"}, {function() return (#getItem().sockets - getItem().abyssalSocketCount) * 48 - 4 end, 0, 20, 20}, "+", function()
		local item, previousSockets = editItem()
		local insertIndex = #item.sockets - item.abyssalSocketCount + 1
		t_insert(item.sockets, insertIndex, {
			color = item.defaultSocketColor,
			group = (item.sockets[insertIndex - 1] and item.sockets[insertIndex - 1].group or 0) + 1
		})
		for s = insertIndex + 1, #item.sockets do
			item.sockets[s].group = item.sockets[s].group + 1
		end
		commit(previousSockets)
	end)
	controls.displayItemAddSocket.shown = function()
		return #getItem().sockets < getItem().selectableSocketCount + getItem().abyssalSocketCount
	end

	if includeBulkUpdate == false then
		return
	end

	controls.displayItemSetColorsLabel = new("LabelControl"):LabelControl({"LEFT",anchor,"RIGHT"}, {function()
		local socketCount = #getItem().sockets - getItem().abyssalSocketCount
		return socketCount * 48 + (controls.displayItemAddSocket:IsShown() and 28 or 2)
	end, 0, 0, 16}, "^7Bulk Update:")
	controls.displayItemSetColorsLabel.shown = function() return anchor:IsShown() and getItem().selectableSocketCount > 0 end
	controls.displayItemSetColors = new("DropDownControl"):DropDownControl({"LEFT",controls.displayItemSetColorsLabel,"RIGHT"}, {6, 0, m_ceil(DrawStringWidth(16, "VAR", "W")) + 18, 20}, socketColorDropList, function(index, value)
		if not value.color then
			return
		end
		local item, previousSockets = editItem()
		for i, socket in ipairs(item.sockets) do
			if i <= item.selectableSocketCount and socket.color ~= "A" then
				socket.color = value.color
			end
		end
		commit(previousSockets)
		controls.displayItemSetColors:SelByValue("", "label")
	end)
	controls.displayItemSetColors.arrowSize = 6
	controls.displayItemSetColors.shown = controls.displayItemSetColorsLabel.shown
	controls.displayItemSetLinks = new("DropDownControl"):DropDownControl({"LEFT",controls.displayItemSetColors,"RIGHT"}, {6, 0, 18, 20}, { "" }, function(index)
		if index == 1 then
			return
		end
		local item, previousSockets = editItem()
		local linkedSockets = m_min(index - 1, #item.sockets - item.abyssalSocketCount)
		for i, socket in ipairs(item.sockets) do
			socket.group = i <= linkedSockets and 1 or i - linkedSockets + 1
		end
		commit(previousSockets)
		controls.displayItemSetLinks:SelByValue("")
	end)
	controls.displayItemSetLinks.arrowSize = 6
	controls.displayItemSetLinks.shown = controls.displayItemSetColorsLabel.shown
	controls.displayItemSetLinks.tooltipText = "Link the first selected number of existing sockets; leave the remaining sockets unlinked."

end

function socketControls.update(controls, item)
	local sockets = item.sockets
	for i = 1, #sockets - item.abyssalSocketCount do
		controls["displayItemSocket"..i]:SelByValue(sockets[i].color, "color")
		if i > 1 then
			controls["displayItemLink"..(i-1)].state = sockets[i].group == sockets[i-1].group
		end
	end
	local links = controls.displayItemSetLinks
	if not links then
		return
	end
	local socketCount = #sockets - item.abyssalSocketCount
	if #links.list ~= socketCount + 1 then
		local linkList = { "" }
		local linkWidth = 0
		for count = 1, socketCount do
			local label = count .. "L"
			t_insert(linkList, label)
			linkWidth = m_max(linkWidth, DrawStringWidth(16, "VAR", label))
		end
		if links.selIndex > #linkList then
			links:SetSel(1, true)
		end
		links.width = m_ceil(linkWidth) + 18
		links:SetList(linkList)
		links:UpdateSearch()
	end
end

return socketControls
