local CONST = require(script.Parent.Parent:WaitForChild("Constants"))
local Sandbox = require(script.Parent:WaitForChild("Sandbox"))

local pluginAPI = {}

pluginAPI.CollisionEnabled = true
pluginAPI.GridSize = 1

local pluginState = setmetatable({}, CONST.WEAK_METATABLES.Keys)

function pluginAPI:GetSelectedRibbonTool()
	return Enum.RibbonTool.None
end
function pluginAPI:GetJoinMode()
	return Enum.JointCreationMode.None
end

function pluginAPI:Activate(exclusiveMouse: boolean)
	local state = pluginState[self]
	if not state then
		state = {}
		pluginState[self] = state
	end

	state.ExclusiveMouse = exclusiveMouse
	state.Active = true
end
function pluginAPI:Deactivate()
	local state = pluginState[self]
	if not state then
		state = {}
		pluginState[self] = state
	end

	state.ExclusiveMouse = nil
	state.Active = false
end
function pluginAPI:IsActivated()
	local state = pluginState[self]
	if not state then
		state = {}
		pluginState[self] = state
	end

	return state.Active
end
function pluginAPI:IsActivatedWithExclusiveMouse()
	local state = pluginState[self]
	if not state then
		state = {}
		pluginState[self] = state
	end

	return state.Active and state.ExclusiveMouse
end

function pluginAPI:Union(parts)
	-- if Plugin.UnionOperations then
	-- 	-- TODO
	-- end
end
function pluginAPI:Separate(parts)
	-- if Plugin.UnionOperations then
	-- 	-- TODO
	-- end
end
function pluginAPI:Negate(parts)
	-- if Plugin.UnionOperations then
	-- 	-- TODO
	-- end
end

function pluginAPI:SelectRibbonTool(tool: Enum.RibbonTool, position: UDim2)
	
end

function pluginAPI:OpenScript(script: LuaSourceContainer, lineNumber: number)
	
end
function pluginAPI:OpenWikiPage(url: string)
	
end

function pluginAPI:CreateDockWidgetPluginGui(pluginGuiId: string, dockWidgetPluginGuiInfo: DockWidgetPluginGuiInfo): DockWidgetPluginGui
	-- TODO
end
function pluginAPI:CreatePluginAction(actionId: string, text: string, statusTip: string, iconName: string, allowBinding: boolean): PluginAction
	-- TODO
end
function pluginAPI:CreatePluginMenu(id: string, title: string, icon: string): PluginMenu
	-- TODO
end
function pluginAPI:CreateToolbar(name: string): PluginToolbar
	-- TODO
end
function pluginAPI:GetMouse(): PluginMouse
	-- TODO (Require client-side execution & grab player mouse)
	-- Or emulate a PluginMouse via remotes
end

function pluginAPI:PromptForExistingAssetId(assetType: string): number
	return -1
end
function pluginAPI:PromptSaveSelection(suggestedFileName: string): boolean
	return false
end

function pluginAPI:StartDrag()

end
function pluginAPI:ImportFbxRig()
	return nil
end
function pluginAPI:ImportFbxAnimation()
	return nil
end

-- Plugin setting emulation
local pluginSettings = setmetatable({}, CONST.WEAK_METATABLES.Keys)
function pluginAPI:GetSetting(key: string): any
	local localSettings = pluginSettings[self]
	if not localSettings then
		localSettings = {}
		pluginSettings[self] = localSettings
	end
	
	return localSettings[key]
end
function pluginAPI:SetSetting(key: string, value: any)
	local localSettings = pluginSettings[self]
	if not localSettings then
		localSettings = {}
		pluginSettings[self] = localSettings
	end
	
	localSettings[key] = value
end

local deactivationEvent = Instance.new("BindableEvent")
local unloadEvent = Instance.new("BindableEvent")

local events = {
	Deactivation = deactivationEvent.Event,
	Unloading = unloadEvent.Event
}

setmetatable(pluginAPI, {
	__index = function(plugin, index)
		if events[index] then
			return events[index]
		end
		if rawequal(index, "Parent") then
			return nil
		end
		error(string.format("%s is not a valid member of Plugin \"%s\"", tostring(index), tostring(plugin)), 2)
	end,
	__newindex = function(plugin, index)
		if rawequal(index, "Parent") then
			return
		end
		if events[index] then
			error(string.format("Unable to assign property %s. Property is read only", tostring(index)), 2)
		end
		error(string.format("%s is not a valid member of Plugin \"%s\"", tostring(index), tostring(plugin)), 2)
	end
})

local Plugin = {}

Plugin.EmulatedAPI = pluginAPI

--[=[
	Creates a sandbox configured for emulating Roblox plugins. (WIP)
]=]
function Plugin.new(options)
	local sandbox = Sandbox.new(options)

	-- TODO: Compatability
	-- TODO: Define "plugin" (Finish definition API)

	local plugin = newproxy(true)

	local meta = getmetatable(plugin)

	meta.__index = pluginAPI
	meta.__newindex = pluginAPI
	meta.__tostring = function()
		return "plugin"
	end

	meta.__metatable = "The metatable is locked"

	sandbox.BaseEnvironment.env.plugin = plugin

	sandbox.Plugin = plugin

	function sandbox:BindToPlayer(player: Player)
		-- TODO: Client-side input emulation
	end

	return sandbox
end

return Plugin