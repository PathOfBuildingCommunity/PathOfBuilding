-- Path of Building
--
-- Module: Tree Tab
-- Passive skill tree tab for the current build.
--
local launch, main = ...

local ipairs = ipairs

local TreeTabClass = common.NewClass("TreeTab", "ControlHost", function(self, build)
	self.ControlHost()

	self.build = build

	self.viewer = common.New("PassiveTreeView")

	self.anchorControls = common.New("Control", nil, 0, 0, 0, 20)
	self.controls.reset = common.New("ButtonControl", {"LEFT",self.anchorControls,"RIGHT"}, 0, 0, 60, 20, "Reset", function()
		main:OpenConfirmPopup("Reset Tree", "Are you sure you want to reset your passive tree?", "Reset", function()
			self.build.spec:ResetNodes()
			self.build.spec:AddUndoState()
			self.build.buildFlag = true
		end)			
	end)
	self.controls.import = common.New("ButtonControl", {"LEFT",self.controls.reset,"RIGHT"}, 8, 0, 90, 20, "Import Tree", function()
		local treeLink = ""
		local showMsg
		main:OpenPopup(280, 110, "Import Tree", {
			common.New("LabelControl", nil, 0, 20, 0, 16, "Enter passive tree link:"),
			common.New("EditControl", nil, 0, 40, 250, 18, "", nil, nil, nil, function(buf)
				treeLink = buf 
				showMsg = nil
			end),
			common.New("LabelControl", nil, 0, 58, 0, 16, function() return showMsg or "" end),
			common.New("ButtonControl", nil, -45, 80, 80, 20, "Import", function()
				if #treeLink > 0 then
					local errMsg = self.build.spec:DecodeURL(treeLink)
					if errMsg then
						showMsg = "^1"..errMsg
					else
						self.build.spec:AddUndoState()
						self.build.buildFlag = true
						main:ClosePopup()
					end
				end
			end),
			common.New("ButtonControl", nil, 45, 80, 80, 20, "Cancel", function()
				main:ClosePopup()
			end),
		})
	end)
	self.controls.export = common.New("ButtonControl", {"LEFT",self.controls.import,"RIGHT"}, 8, 0, 90, 20, "Export Tree", function()
		local treeLink = self.build.spec:EncodeURL("https://www.pathofexile.com/passive-skill-tree/")
		main:OpenPopup(280, 100, "Export Tree", {
			common.New("LabelControl", nil, 0, 20, 0, 16, "Passive tree link:"),
			common.New("EditControl", nil, 0, 40, 250, 18, treeLink, nil, "[%z]"),
			common.New("ButtonControl", nil, -45, 70, 80, 20, "Copy", function()
				Copy(treeLink)
			end),
			common.New("ButtonControl", nil, 45, 70, 80, 20, "Done", function()
				main:ClosePopup()
			end),
		})
	end)
	self.controls.treeSearch = common.New("EditControl", {"LEFT",self.controls.export,"RIGHT"}, 8, 0, 400, 20, "", "Search", "[^%c%(%)]", 100, function(buf)
		self.viewer.searchStr = buf
	end)
	self.controls.treeHeatMap = common.New("CheckBoxControl", {"LEFT",self.controls.treeSearch,"RIGHT"}, 130, 0, 20, "Show node power:", function(state)	
		self.viewer.showHeatMap = state
	end)
	self.controls.treeHeatMap.tooltip = "When enabled, an estimate of the offensive and defensive strength of\neach unallocated passive is calculated and displayed visually.\nOffensive power shows as red, defensive power as blue."
end)

function TreeTabClass:Draw(viewPort, inputEvents)
	viewPort.height = viewPort.height - 32
	self.anchorControls.x = viewPort.x + 4
	self.anchorControls.y = viewPort.y + viewPort.height + 8

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self.build.spec:Undo()
				self.build.buildFlag = true
				inputEvents[id] = nil
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self.build.spec:Redo()
				self.build.buildFlag = true
				inputEvents[id] = nil
			end
		end
	end
	self:ProcessControlsInput(inputEvents)

	self.viewer:Draw(self.build, viewPort, inputEvents)

	if not self.controls.treeSearch.hasFocus then
		self.controls.treeSearch:SetText(self.viewer.searchStr)
	end
	self.controls.treeHeatMap.state = self.viewer.showHeatMap

	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height + 4, viewPort.width, 28)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height, viewPort.width, 4)

	self:DrawControls(viewPort)
end