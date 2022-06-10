--!strict
local H6x = require(script.Parent:WaitForChild("H6x"))
local CONST = require(script.Parent:WaitForChild("Constants"))
local Util = require(script.Parent:WaitForChild("Util"))
local Logger = require(script.Parent:WaitForChild("Logger"))
local Reflector = require(script.Parent:WaitForChild("Reflector"))

local Sandbox = {}

function Sandbox:LoadFunction<T>(target: T & (...any?) -> ...any?): typeof(target())
	assert(target and type(target) == "function", "First argument to LoadFunction must be a function.")
	return self:Export(self.BaseEnvironment:Apply(target))
end

function Sandbox:LoadString(source: string)
	assert(source and type(source) == "string", "Source code must be a string.")
	local success, result = loadstring(source)
	return self:LoadFunction(assert(success, result))
end

-- Executes a function inside the sandbox environment.
function Sandbox:ExecuteFunction<T>(target: T & (...any?) -> ...any?, ...): typeof(target())
	return self.BaseRunner:ExecuteFunction(target, ...)
end

-- Executes a string inside the sandbox environment.
function Sandbox:ExecuteString(source: string, ...): ...any
	return self.BaseRunner:ExecuteString(source, ...)
end

export type RuleKind = "Terminate" | "Block" | "Allow" | "Redirect" | "Inject"; -- Kinds of actions to take when a matched item is found
local RULE_KINDS = {
	Terminate = "Terminate",
	Block = "Block",
	Allow = "Allow",
	Redirect = "Redirect",
	Inject = "Inject"
}
export type RuleMode = -- Determines how matches are selected
	"ByReference" | -- Matches values by reference equality (As table key)
	"ByTypeOf" | -- Matches values by typeof
	"ClassEquals" | -- Matches Instances by explicit ClassName equality
	"IsA" | -- Matches Instances by IsA
	"IsDescendantOfInclusive" | -- Matches Instances by IsDescendantOf, including the target
	"IsAncestorOfInclusive" | -- Matches Instances by IsAncestorOf, including the target
	"IsAncestorOfExclusive" | -- Matches Instances by IsAncestorOf, excluding the target
	"IsDescendantOfExclusive"; -- Matches Instances by IsDescendantOf, excluding the target

-- Set of valid rules
export type SandboxRule = {
	-- Either blocks or allows a matched value
	-- Terminate is like Block except it terminates execution of code within the sandbox
	Rule: "Terminate" | "Block" | "Allow";
	Mode: RuleMode;
	Order: number?;
	Target: any;
} | {
	-- Redirects matched values to another
	Rule: "Redirect";
	Mode: RuleMode;
	Order: number?;
	Target: any;
	Replacement: any;
} | {
	-- Matches a value & calls a function (sandboxed!) to get a replacement
	Rule: "Inject";
	Mode: RuleMode;
	Order: number?;
	Target: any;
	Callback: (any) -> any; -- Must accept the input value and return a replacement or terminate the sandbox
}

--[=[
	Checks if two references are equal.
]=]
local function refequals(referenceA: any?, referenceB: any?): boolean
	local ref = {}
	ref[referenceA] = true
	return ref[referenceB] or false
end

--[=[
	Adds a new rule to the sandbox.
]=]
function Sandbox:AddRule(rule: SandboxRule)
	assert(typeof(rule) == "table", "SandboxRule must be a table.")
	assert(typeof(rule.Rule) == "string", "SandboxRule.Rule must be a string.")
	assert(typeof(rule.Mode) == "string", "SandboxRule.Mode must be a string.")

	assert(RULE_KINDS[rule.Rule], "SandboxRule.Rule must be a valid rule kind.")

	table.insert(self.Rules, rule)
	self.Rules.Dirty = true -- Mark dirty (rules need to be sorted again)

	return rule
end

--[=[
	Removes a previously added rule from the sandbox.
]=]
function Sandbox:RemoveRule(rule: SandboxRule)
	local index = table.find(self.Rules, rule)
	if index then
		table.remove(self.Rules, index)
	end
end

--[=[
	Sorts the sandbox rules by their Order properties, with the *lowest* order first (most important).
]=]
function Sandbox:UpdateRuleOrders()
	if not self.Rules.Dirty then
		return
	end
	table.sort(self.Rules, function(ruleA: SandboxRule, ruleB: SandboxRule)
		return (ruleA.Order or 0) < (ruleB.Order or 0)
	end)
	self.Rules.Dirty = false
end

--[=[
	Checks if a rule matches a given value.
	@return boolean -- Whether or not the rule matches the value
]=]
function Sandbox:RuleMatches(rule: SandboxRule, value: any): boolean
	self:UpdateRuleOrders() -- Update rule orders

	local mode = rule.Mode
	local target = rule.Target

	-- Do not match primitives
	if not value or CONST.PRIMITIVES[type(value)] then
		return false
	end

	if mode == "ByReference" then
		return refequals(target, value)
	elseif mode == "ByTypeOf" then
		return typeof(value) == target
	elseif mode == "ClassEquals" then
		return typeof(value) == "Instance" and value.ClassName == target
	elseif mode == "IsA" then
		return typeof(value) == "Instance" and value:IsA(target)
	elseif mode == "IsDescendantOfInclusive" then
		return typeof(value) == "Instance" and (target == value or target:IsAncestorOf(value))
	elseif mode == "IsAncestorOfInclusive" then
		return typeof(value) == "Instance" and (target == value or target:DescendantOf(value))
	elseif mode == "IsDescendantOfExclusive" then
		return typeof(value) == "Instance" and target:IsAncestorOf(value)
	elseif mode == "IsAncestorOfExclusive" then
		return typeof(value) == "Instance" and target:IsDescendantOf(value)
	else
		error("Invalid SandboxRule.Mode", 2)
	end
end

--[=[
	Sanitizes a value by the sandbox's rules.
	@return any -- The sanitized value
]=]
function Sandbox:Sanitize(value: any): any
	if not value or CONST.PRIMITIVES[type(value)] then
		return value
	end

	for _, rule in ipairs(self.Rules) do
		if self:RuleMatches(rule, value) then
			if rule.Rule == "Terminate" then
				self:Terminate(true)
			elseif rule.Rule == "Block" then
				return nil
			elseif rule.Rule == "Allow" then
				return value
			elseif rule.Rule == "Redirect" then
				return rule.Replacement
			elseif rule.Rule == "Inject" then
				return rule.Callback(value)
			end
		end
	end
	return value
end

--[=[
	Produces a report of the sandbox's monitored activity.
]=]
function Sandbox:GenerateActivityReport(format: string)
	return self.SandboxActivity:GenerateReport(format)
end

--[=[
	Inserts an event into the Sandbox's activity log.
]=]
function Sandbox:ActivityEvent(eventType: string, ...)
	local activity = self.SandboxActivity
	local event = activity[eventType]

	event:Track(...)
end

--[=[
	Sets which mode to use when emulating require calls.
]=]
function Sandbox:SetRequireMode(mode: string | (...any?) -> ...any?)
	assert(type(mode) == "string" or type(mode) == "function", "Mode must be a string or a function.")
	if type(mode) == "function" then
		self.CustomRequire = mode
		mode = "custom"
	end
	self.RequireMode = mode
end

--[=[
	Inserts a module for the sandbox to return when require is called.
]=]
function Sandbox:AddModule(moduleName: string, module: any)
	self.Modules[moduleName] = module
end

--[=[
	Sets the script reference of the sandbox.
]=]
function Sandbox:SetScript(script: Script?)
	if self.ScriptRule then
		self:RemoveRule(self.ScriptRule)
	end
	self.ScriptRule = self:AddRule({
		Rule = "Redirect",
		Mode = "ByReference",
		Order = -math.huge, -- Highest priority
		Target = self.BaseEnvironment.subenv.script,
		Replacement = script
	})
end

--[=[
	Adds the default security rules to the sandbox. It is recommended that you do not remove these rules.
]=]
function Sandbox:AddDefaultSecurityRules(allowInstances: boolean?)
	local function block(target)
		if not CONST.PRIMITIVES[type(target)] then
			self:AddRule({
				Rule = "Terminate";
				Mode = "ByReference";
				Order = -math.huge;
				Target = target;
			})
		end
	end
	
	block(H6x) -- Block H6x
	for index, value in pairs(H6x) do -- Block everything directly inside
		block(index)
		block(value)
	end
	block(self) -- Block sandbox
	self:AddRule({ -- Block entire H6x tree
		Rule = "Block";
		Mode = "IsDescendantOfInclusive";
		Order = -math.huge;
		Target = script.Parent;
	})

	self:SetScript(Instance.new("Script"))
	if allowInstances then
		self:AllowInstances()
	else
		self:DenyInstances()
	end
end

--[=[
	Adds the default redirections to the sandbox, for code compatability and increased security. It is recommended that you do not remove these rules.
]=]
function Sandbox:AddDefaultRedirects()
	-- TODO: Emulate wait/delay & task.wait/task.delay
	-- Currently, not doing so results in an error in some code ("cannot resume dead coroutine")

	-- Require emulation
	local realRequire = require
	local function require(...)
		local requireMode = self.RequireMode
		local modules = self.Modules

		if requireMode == "disable" or requireMode == "disabled" then
			return error("Require is disabled.", nil)
		end

		local requireTarget = ...
		if modules[requireTarget] then
			return self:Import(modules[requireTarget])
		end

		if requireMode == "roblox" then
			if type(requireTarget) == "number" then
				if not self.AssetRequiresAllowed then
					return error("Attempted to call require with invalid argument(s).", 2)
				end
			end

			local results = table.pack(pcall(realRequire, requireTarget, select(2, ...)))

			if not results[1] then
				error(results[2], 2)
			end

			table.remove(results, 1)
			results.n -= 1

			return Util.unpack(results)
		elseif requireMode == "vanilla" then
			if type(requireTarget) ~= "string" then
				return error(string.format("bad argument #1 to 'require' (string expected, got %s)", type(requireTarget)), 2)
			end
			return error(string.format("module '%s' not found:\n        no file './%s.lua'", requireTarget, requireTarget), 2)
		elseif requireMode == "custom" then
			local requireHook = self.CustomRequire

			if requireHook then
				local results = table.pack(pcall(requireHook, ...))

				if not results[1] then
					error(results[2], 2)
				end

				table.remove(results, 1)
				results.n -= 1

				return Util.unpack(results)
			end
		end
		return nil
	end

	-- Redirect the real require function to our custom require function
	self:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Order = 1;
		Target = realRequire;
		Replacement = self:Import(require);
	})

	-- Redirect the base environment's sub-environment to the sandbox's environment
	local baseEnv = self.BaseEnvironment
	self:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Order = -math.huge; -- Highest priority
		Target = baseEnv.subenv;
		Replacement = baseEnv.env;
	})
end

local function killThread(thread): boolean
	local status = coroutine.status(thread)
	if status ~= "dead" then
		if status == "suspended" then
			-- Close the thread
			coroutine.close(thread)
		elseif status ~= "running" then
			Logger:Notice("An unexpected thread status was encountered while terminating:", status)
		end
	end
	return false
end

--[=[
	Checks if the sandbox is supposed to be terminated, and if so, stops execution.
]=]
function Sandbox:CheckTermination()
	if self.Terminated then
		self:Terminate(true)
	end
end

--[=[
	Terminates the sandbox and stops code from running.
]=]
function Sandbox:Terminate(terminateCaller: boolean?)
	if self.Terminated then
		return
	end
	self.Terminated = true

	-- Disable the runner script if it can be
	local runner = self.BaseRunner
	local scriptObject = runner.ScriptObject

	if scriptObject:IsA("BaseScript") then
		scriptObject.Disabled = true
	end

	-- Get tracked values so we can clean up
	local tracked = self.Tracked
	local threads = tracked.Threads
	local connections = tracked.RBXScriptConnections

	-- Disconnect all event connections
	for _, connection in ipairs(connections) do
		connection:Disconnect() -- Disconnect event connection
	end

	-- Kill all threads
	for _, thread in ipairs(threads) do
		killThread(thread)
	end

	-- Remove tracked values
	self.Tracked = nil

	-- Terminate the caller if flagged
	if terminateCaller then
		error("Thread terminated.")
	end
end

--[=[
	Allows the sandbox to use instances.
]=]
function Sandbox:AllowInstances()
	if self.InstanceRule then
		self:RemoveRule(self.InstanceRule)
	end
	self.InstanceRule = self:AddRule({
		Rule = "Allow";
		Mode = "ByTypeOf";
		Order = 1;
		Target = "Instance";
	})
end
--[=[
	Denies the sandbox from use instances (this is the default).
]=]
function Sandbox:DenyInstances()
	if self.InstanceRule then
		self:RemoveRule(self.InstanceRule)
	end
	self.InstanceRule = self:AddRule({
		Rule = "Block";
		Mode = "ByTypeOf";
		Order = 1;
		Target = "Instance";
	})
end

Sandbox.Empty = require(script:WaitForChild("Empty"))
Sandbox.RBXLimited = require(script:WaitForChild("RBXLimited"))
Sandbox.RBXUnlimited = require(script:WaitForChild("RBXUnlimited"))
Sandbox.User = require(script:WaitForChild("User"))
Sandbox.Vanilla = require(script:WaitForChild("Vanilla"))
Sandbox.Plugin = require(script:WaitForChild("Plugin"))

Sandbox.Sandbox = require(script:WaitForChild("Sandbox"))
Sandbox.Sandbox.__index = Sandbox

Sandbox.new = Sandbox.Sandbox.new

function Sandbox:WriteImported(value, imported)
	if not imported then
		return value
	end

	local Poison = self.Poison
	if rawequal(Poison.ToImport[value], nil) and rawequal(Poison.ToImport[imported], nil) then
		Poison.ToImport[value] = imported
		Poison.ToImport[imported] = imported
		Poison.ToClean[imported] = value
	end
	return Poison.ToImport[value]
end

function Sandbox:WriteExported(value, exported)
	if not exported then
		return value
	end

	local Poison = self.Poison
	if rawequal(Poison.ToExport[value], nil) and rawequal(Poison.ToExport[exported], nil) then
		Poison.ToExport[value] = exported
		Poison.ToExport[exported] = exported
		Poison.ToClean[exported] = value
	end
	return Poison.ToExport[value]
end

function Sandbox:CreateProxy(value: any, metatable: {[string]: any})
	if CONST.PRIMITIVES[type(value)] then
		return
	end

	if type(value) == "table" then
		local proxy = {}--Util.copy(value)
		setmetatable(proxy, Reflector.from(value, metatable, self))
		-- Also freeze the table if applicable
		if table.isfrozen(value) then
			table.freeze(proxy)
		end
		return proxy
	elseif type(value) == "userdata" then
		local proxy = newproxy(true)
		local meta = getmetatable(proxy)
		-- Write the metatable into the userdata
		for index, metamethod in pairs(Reflector.from(value, metatable, self)) do
			meta[index] = metamethod
		end
		table.freeze(meta) -- Freeze the metatable
		return proxy
	elseif type(value) == "function" then
		return function(...)
			return metatable.__call(value, ...)
		end
	else
		Logger:Error("Unsupported type:", type(value))
	end
end

--[=[
	Marks a thread as being owned by the sandbox. It will be terminated if the sandbox is terminated.
	The default is to mark the running thread.
]=]
function Sandbox:TrackThread(thread: thread?)
	if self.Terminated then
		return
	end
	local tracked = self.Tracked
	local threads = tracked.Threads
	table.insert(threads, thread or coroutine.running())
end

--[=[
	Marks an RBXScriptConnection as being owned by the sandbox. It will be disconnected if the sandbox is terminated.
]=]
function Sandbox:TrackConnection(connection: RBXScriptConnection)
	if self.Terminated then
		return
	end
	local tracked = self.Tracked
	local connections = tracked.RBXScriptConnections
	table.insert(connections, connection)
end

--[=[
	Takes an external value and returns a version safe for the sandbox to use.
]=]
function Sandbox:Import(value: any)
	value = self:GetClean(value)
	value = self:Sanitize(value)
	if CONST.PRIMITIVES[type(value)] then
		return value
	end

	local Poison = self.Poison
	if not Poison.ToImport[value] then
		-- Track imported connections
		if typeof(value) == "RBXScriptConnection" then
			self:TrackConnection(value)
		end
		return self:WriteImported(value, self:CreateProxy(value, self.ImportMetatable))
	end
	return Poison.ToImport[value] or value
end
--[=[
	Takes a value created by the sandbox and returns a safe version of it.
]=]
function Sandbox:Export(value: any)
	value = self:GetClean(value)
	value = self:Sanitize(value)
	if CONST.PRIMITIVES[type(value)] then
		return value
	end

	local Poison = self.Poison
	if not Poison.ToExport[value] then
		return self:WriteExported(value, self:CreateProxy(value, self.ExportMetatable))
	end
	return Poison.ToExport[value] or value
end

--[=[
	Takes an imported or exported value and returns the original.
]=]
function Sandbox:GetClean(value: any)
	if CONST.PRIMITIVES[type(value)] then
		return value
	end
	return self.Poison.ToClean[value] or value
end

return Sandbox