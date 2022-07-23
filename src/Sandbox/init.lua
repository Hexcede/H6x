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

export type RuleKind = -- Kinds of actions to take when a matched item is found
	"Terminate" | -- Terminates the sandbox on access (Does not provide any special security)
	"Block" | -- Blocks the item from being accessed
	"Allow" | -- Allows the item to be accessed immediately, skipping any remaining rules
	"Redirect" | -- Changes the value into another
	"Inject" | -- Calls a function which takes the value in and returns the new value
	"Proxy"; -- Creates a proxy around the value to modify its behaviour
local RULE_KINDS = {
	Terminate = "Terminate";
	Block = "Block";
	Allow = "Allow";
	Redirect = "Redirect";
	Inject = "Inject";
	Proxy = "Proxy";
}
export type RuleMode = -- Determines how matches are selected
	"ByReference" | -- Matches values by reference equality (As table key)
	"ByTypeOf" | -- Matches values by typeof
	"ClassEquals" | -- Matches Instances by explicit ClassName equality
	"IsA" | -- Matches Instances by IsA
	"IsDescendantOfInclusive" | -- Matches Instances by IsDescendantOf, including the target
	"IsAncestorOfInclusive" | -- Matches Instances by IsAncestorOf, including the target
	"IsAncestorOfExclusive" | -- Matches Instances by IsAncestorOf, excluding the target
	"IsDescendantOfExclusive" | -- Matches Instances by IsDescendantOf, excluding the target
	"ByCallback"; -- Matches values by a callback which takes the value in, and returns a truthy or falsy match
					-- Note: This can be slow if you're not careful! It's called against all values
export type ProxyRuleMode = RuleMode |
	"ByIndex"; -- Matches values by their index on the proxy

-- Set of valid rules
export type Rule<Mode> = {
	-- Either blocks or allows a matched value
	-- Terminate is like Block except it terminates execution of code within the sandbox
	Rule: "Terminate" | "Block" | "Allow";
	Mode: Mode;
	Order: number?;
	Target: any;
} | {
	-- Redirects matched values to another
	Rule: "Redirect";
	Mode: Mode;
	Order: number?;
	Target: any;
	Replacement: any;
} | {
	-- Matches a value & calls a function (sandboxed!) to get a replacement
	Rule: "Inject";
	Mode: Mode;
	Order: number?;
	Target: any;
	Callback: (any) -> any; -- Must accept the input value and return a replacement or terminate the sandbox
} | {
	-- Matches a value, and returns a special proxy which is correctly recognized by the sandbox
	-- The proxy contains a set of sub-rules in its ProxyRules section
	-- NOTE: The ProxyRules table will be sorted
	Rule: "Proxy";
	Mode: Mode;
	Order: number?;
	Target: any;

	ProxyRules: { Rule<ProxyRuleMode> };
}
export type SandboxRule = Rule<RuleMode>;

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
function Sandbox:RuleMatches<T>(rule: Rule<T>, value: any): boolean?
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
	elseif mode == "ByCallback" then
		return if target(value, rule) then true else false
	end
	error("Invalid Rule.Mode", 2)
end

--[=[
	Sanitizes a value by the sandbox's rules.
	@return any -- The sanitized value
]=]
function Sandbox:Sanitize<T>(value: any, rules: {Rule<T>}?): any
	if not value or CONST.PRIMITIVES[type(value)] then
		return value
	end

	for _, rule in ipairs(rules or self.Rules) do
		if self:RuleMatches(rule, value) then
			if rule.Rule == "Terminate" then
				self:Terminate(true)
				return nil
			elseif rule.Rule == "Block" then
				return nil
			elseif rule.Rule == "Allow" then
				return value
			elseif rule.Rule == "Redirect" then
				return rule.Replacement
			elseif rule.Rule == "Inject" then
				return (rule.Callback(value))
			elseif rule.Rule == "Proxy" then
				-- TODO: Create proxy
				return
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

	local selfEnvironment = getfenv()
	local callerEnvironment = getfenv(2)
	
	block(selfEnvironment) -- Block local environment
	block(callerEnvironment) -- Block caller environment
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

	local MAX_LEVEL = 2^16
	local function getfenvsafe(level: number)
		return debug.info(level, "f") and getfenv(debug.info(level + 1, "f"))
	end
	local function shouldSkipEnvironment(env: any?): boolean
		return rawequal(env, selfEnvironment) or rawequal(env, callerEnvironment)
	end
	local function seekEnvironment(level: number, findStackSize: boolean?): number
		if level == 0 and not findStackSize then
			return 0
		end

		local envList = table.create(level)
		local currentLevel = 1
		local env = getfenvsafe(currentLevel + 1)
		local base = 0
		while env do
			if not shouldSkipEnvironment(env) then
				base = base or currentLevel
				table.insert(envList, currentLevel)
				if level ~= 0 and #envList >= level then
					break
				end
			end
			currentLevel += 1
			env = getfenvsafe(currentLevel + 1)
		end
		if level == 0 then
			level = #envList
		end
		if envList[level] then
			return envList[level]
		end
		return math.max(MAX_LEVEL, currentLevel + 1)
	end
	
	local _getfenv = getfenv
	local function getfenv(levelOrFunction)
		if type(levelOrFunction) == "number" then
			-- Otherwise, skip over disallowed environments
			return _getfenv(seekEnvironment(levelOrFunction, true))
		end
		return _getfenv(levelOrFunction)
	end
	self:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Order = -math.huge; -- Highest priority
		Target = _getfenv;
		Replacement = self:Import(getfenv);
	})

	local _setfenv = setfenv
	local function setfenv(levelOrFunction, env)
		if type(levelOrFunction) == "number" then
			-- Otherwise, skip over disallowed environments
			return _setfenv(seekEnvironment(levelOrFunction, true), env)
		end
		return _setfenv(levelOrFunction, env)
	end
	self:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Order = -math.huge; -- Highest priority
		Target = _setfenv;
		Replacement = self:Import(setfenv);
	})

	local _error = error
	local function error(message, level)
		if type(level) == "number" then
			level = seekEnvironment(level, true)
		end
		return _error(message, level)
	end
	self:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Order = -math.huge; -- Highest priority
		Target = _error;
		Replacement = self:Import(error);
	})

	local debug_info = debug.info
	local function info(...)
		local nargs = select("#", ...)
		if nargs >= 0 and nargs <= 1 then
			return debug_info(...)
		elseif nargs == 2 then
			local levelOrFunction, options = ...
			if type(levelOrFunction) == "number" then
				levelOrFunction = seekEnvironment(levelOrFunction)
			end
			return debug_info(levelOrFunction, options)
		end

		local thread, level, options = ...
		if not thread or rawequal(thread, coroutine.running()) then
			if type(level) == "number" then
				level = seekEnvironment(level)
			end
		end
		return debug_info(thread, level, options, select(4, ...))
	end
	self:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Order = -math.huge; -- Highest priority
		Target = debug_info;
		Replacement = self:Import(info);
	})

	local debug_traceback = debug.traceback
	local function traceback(...)
		local nargs = select("#", ...)
		if nargs == 0 then
			return debug_traceback(seekEnvironment(2, true))
		elseif nargs == 1 then
			return debug_traceback(..., seekEnvironment(2, true))
		elseif nargs == 2 then
			local message, level = ...
			if type(level) == "number" then
				level = seekEnvironment(level, true)
			end
			return debug_traceback(message, level)
		end

		local thread, message, level = ...
		if rawequal(thread, coroutine.running()) then
			if type(level) == "number" then
				level = seekEnvironment(level, true)
			end
		end
		return debug_traceback(thread, message, level, select(4, ...))
	end
	self:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Order = -math.huge; -- Highest priority
		Target = debug_traceback;
		Replacement = self:Import(traceback)
	})
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
		if status == "suspended" or status == "normal" then
			-- Close the thread
			coroutine.close(thread)
		elseif status ~= "running" then
			Logger:Notice("An unexpected thread status was encountered while terminating:", status)
		end
	end
	return false
end

--[=[
	Returns the amount of CPU time the sandbox has used.
]=]
function Sandbox:GetCPUTimeNow()
	local cpuTime = self.CPUTime
	local timer = self.Timers[#self.Timers]
	if timer then
		cpuTime += os.clock() - timer
	end
	return cpuTime
end

--[=[
	Returns whether or not the sandbox is running.
]=]
function Sandbox:IsRunning()
	-- We use sandbox timers to determine if the sandbox is running
	-- If the sandbox has an active timer, it is considered running
	return if self.Timers[1] then true else false
end

--[=[
	Begins measuring the sandbox's execution time.
	You do not need to call this yourself, it is called automatically.
]=]
function Sandbox:BeginTimer()
	table.insert(self.Timers, os.clock())
end

--[=[
	Stops measuring the sandbox's execution time and updates CPUTime.
	You do not need to call this yourself, it is called automatically.
]=]
function Sandbox:EndTimer()
	if not self:IsRunning() then
		return
	end
	-- Measure execution time and increase CPUTime
	local timer = table.remove(self.Timers, #self.Timers)
	if timer then
		self.CPUTime += os.clock() - timer
	end
end

--[=[
	Calls Sandbox:EndTimer() for all active timers.
]=]
function Sandbox:EndAllTimers()
	-- End all timers
	while self.Timers[1] do
		self:EndTimer()
	end
end

--[=[
	Resets all of the sandbox's timers.
]=]
function Sandbox:ResetTimers()
	self.CPUTime = 0
	self.Timers = {}
end

--[=[
	Sets the sandbox's CPU timeout (in seconds) and resets all timers.
	Passing nil or 0 will remove the configured timeout.
]=]
function Sandbox:SetTimeout(timeout: number?)
	self:ResetTimers()
	if timeout == nil or timeout == 0 then
		self.Timeout = nil
	else
		self.Timeout = timeout
	end
end

--[=[
	Checks if the sandbox has timed out. If so, it will be terminated immediately.
	You do not need to call this yourself, it is called automatically.
]=]
function Sandbox:CheckTimeout()
	local timeout = self.Timeout
	if timeout then
		-- Measure how much CPU time the sandbox has used, and terminate it if it has run for too long.
		local cpuTime = self:GetCPUTimeNow()
		if cpuTime >= timeout then
			-- Logger:Notice("Sandbox timed out after", cpuTime, "seconds.")
			self:Terminate()
		end
	end
end

--[=[
	Do not call this function.
	This function is called automatically when code inside the sandbox triggers any managed code.
	It is used to determine if the sandbox needs to terminate/has terminated, and if so, will cease execution immediately.
]=]
function Sandbox:ProcessTermination()
	self:CheckTimeout()
	if self.Terminated then
		self:Terminate(true)
	end
end

--[=[
	Terminates the sandbox and stops code from running.
]=]
function Sandbox:Terminate(terminateCaller: boolean?)
	if not self.Terminated then
		self.Terminated = true
		self:EndAllTimers()

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
	end

	-- Terminate the caller if specified
	if terminateCaller then
		error(nil, 0)
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

	if not thread then
		thread = coroutine.running()
		if not self.ThreadTimer then
			self.ThreadTimer = os.clock()
			self:BeginTimer() -- Begin a timer for the thread
			-- Defer and end the thread timer
			task.defer(function()
				self.ThreadTimer = nil
				self:EndTimer()
			end)
		end
	end

	local tracked = self.Tracked
	local threads = tracked.Threads
	if not table.find(threads, thread) then
		table.insert(threads, thread)
	end
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