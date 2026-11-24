-- Path of Building
--
-- Class: MCP Connection List
-- Lists the MCP client sessions connected to this window's MCP server (see Modules/MCPStatus.lua).
--
local s_format = string.format
local os_time = os.time

---@class MCPConnectionListControl: ListControl
local MCPConnectionListClass = newClass("MCPConnectionListControl", "ListControl")

function MCPConnectionListClass:MCPConnectionListControl(anchor, rect, mcpStatus)
	self:ListControl(anchor, rect, 18, "VERTICAL", false, mcpStatus.connections)
	self.mcpStatus = mcpStatus
	self.colLabels = true
	self.showRowSeparators = true
	self.defaultText = "^8No client has connected yet. Add this server to Claude Code (or another MCP client) and it will show up here."
	self.colList = {
		{ label = "Client", width = 220 },
		{ label = "From", width = 110 },
		{ label = "Status", width = 90 },
		{ label = "Calls", width = 60 },
		{ label = "Last tool", width = 150 },
		{ label = "Activity" },
	}
	return self
end

function MCPConnectionListClass:GetRowValue(column, index, session)
	if column == 1 then
		local name = session.title or session.client or "unknown client"
		if session.version then
			name = name .. " ^8" .. session.version
		end
		return name
	elseif column == 2 then
		return session.remote or "?"
	elseif column == 3 then
		if not self.mcpStatus:IsRunning() then
			return "^8server off"
		elseif os_time() - session.lastActivity <= self.mcpStatus.ACTIVE_SECONDS then
			return "^x50E050active"
		end
		return "^8idle"
	elseif column == 4 then
		return tostring(session.calls or 0)
	elseif column == 5 then
		if not session.lastTool then
			return ""
		end
		return (session.lastError and "^1" or "^7") .. session.lastTool
	elseif column == 6 then
		return self.mcpStatus.FormatAge(os_time() - session.lastActivity)
	end
end

function MCPConnectionListClass:AddValueTooltip(tooltip, index, session)
	local format = self.mcpStatus.FormatTime
	tooltip:Clear()
	tooltip:AddLine(16, s_format("^7%s %s", session.title or session.client or "Unknown client", session.version or ""))
	if session.title and session.client then
		tooltip:AddLine(14, "^8Client id: ^7" .. session.client)
	end
	tooltip:AddLine(14, "^8Connected: ^7" .. format(session.connected) .. " ^8from ^7" .. tostring(session.remote))
	tooltip:AddLine(14, "^8Last activity: ^7" .. format(session.lastActivity))
	tooltip:AddLine(14, s_format("^8Requests: ^7%d^8, tool calls: ^7%d", session.requests or 0, session.calls or 0))
	if session.lastTool then
		tooltip:AddLine(14, "^8Last tool: ^7" .. session.lastTool)
	end
	if session.lastError then
		tooltip:AddLine(14, "^8Last error: ^1" .. session.lastError)
	end
	tooltip:AddLine(14, "^8Protocol: ^7" .. tostring(session.protocolVersion) .. "^8, session ^7" .. session.id)
end

function MCPConnectionListClass:OnSelCopy(index, session)
	Copy(session.lastError or session.id)
end
