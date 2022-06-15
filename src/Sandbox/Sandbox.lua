local H6x = require(script.Parent.Parent:WaitForChild("H6x"))
local Reflector = require(script.Parent.Parent:WaitForChild("Reflector"))
local Util = require(script.Parent.Parent:WaitForChild("Util"))

local Sandbox = {}

-- Localize to mitigate against conflicts caused by fenv manipulation
local table = table
local rawget = rawget
local Instance = Instance
local getfenv = getfenv
local setmetatable = setmetatable

local function callCFunctionImport(self, func, ...): typeof(table.pack(...))
	-- Clean all arguments
	local arguments = table.pack(...)
	for i=1, arguments.n do
		arguments[i] = self:GetClean(arguments[i])
	end
	-- Call the function
	local results = table.pack(func(table.unpack(arguments, 1, arguments.n)))
	-- Import all results
	for i=1, results.n do
		results[i] = self:Import(results[i])
	end
	-- Return the results
	return results
end
local function callCFunctionExport(self, func, ...): typeof(table.pack(...))
	-- Clean all arguments
	local arguments = table.pack(...)
	for i=1, arguments.n do
		arguments[i] = self:GetClean(arguments[i])
	end
	-- Call the function
	local results = table.pack(func(table.unpack(arguments, 1, arguments.n)))
	-- Import all results
	for i=1, results.n do
		results[i] = self:GetClean(results[i])--self:Export(results[i])
	end
	-- Return the results
	return results
end
local function callFunctionImported(self, func, ...): typeof(table.pack(...))
	-- Export all arguments
	local arguments = table.pack(...)
	for i=1, arguments.n do
		arguments[i] = self:Export(arguments[i])
	end
	-- Call the function
	local results = table.pack(func(table.unpack(arguments, 1, arguments.n)))
	-- Import all results
	for i=1, results.n do
		results[i] = self:Import(results[i])
	end
	-- Return the results
	return results
end
local function callFunctionExported(self, func, ...): typeof(table.pack(...))
	-- Import all arguments
	local arguments = table.pack(...)
	for i=1, arguments.n do
		arguments[i] = self:Import(arguments[i])
	end
	-- Call the function
	local results = table.pack(func(table.unpack(arguments, 1, arguments.n)))
	-- Export all results
	for i=1, results.n do
		results[i] = self:GetClean(results[i])--self:Export(results[i])
	end
	-- Return the results
	return results
end
-- A helper function which takes in arguments and returns them back so the above functions can be used
local function varg(...)
	return ...
end

--[=[
	Creates a new unconfigured sandbox.
]=]
function Sandbox.new(options)
	local self
	self = {
		Terminated = false,

		RequireMode = "roblox",
		Modules = {},

		Environments = {},

		Rules = {},
		Tracked = {
			Threads = {} :: {thread};
			RBXScriptConnections = {} :: {RBXScriptConnection};
		},

		Poison = {
			ToImport = {};
			ToExport = {};
			ToClean = {};
		},
		ImportMetatable = {
			__call = function(object, ...)
				self:CheckTermination()
				self:TrackThread()
				local real = self:GetClean(object)

				local results = if Util.isCFunction(real) then
					callCFunctionImport(self, real, ...)
				else
					callFunctionImported(self, real, ...)

				self:ActivityEvent("Call", real, table.pack(...), Util.copy(results))
				return table.unpack(results, 1, results.n)
			end,
			__index = function(object, index)
				self:CheckTermination()
				self:TrackThread()

				local real = self:GetClean(object)
				local value = if real then real[self:GetClean(index)] else rawget(object, self:GetClean(index))

				self:ActivityEvent("Get", real, index, value)
				return self:Import(value)
			end,
			__newindex = function(object, index, value)
				self:CheckTermination()
				self:TrackThread()
				index = self:GetClean(index)
				value = self:GetClean(value)

				local real = self:GetClean(object)
				real[index] = value

				self:ActivityEvent("Set", real, index, value)
			end,
			__iter = function(object)
				self:CheckTermination()
				self:TrackThread()

				local real = self:GetClean(object)

				-- TODO: Instead of index, value explicitly, use a vararg if it becomes possible
				--        OR if it becomes possible, correctly wrap the metamethod
				return self:Import(coroutine.wrap(function(object)
					local real = self:GetClean(object)
					-- TODO -- self:ActivityEvent("Iterating", real)
					for index, value, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, A, B, C, D, OVERFLOW in real do
						assert(OVERFLOW == nil, "# of __iter results too long")
						index = self:Import(index)
						if not rawequal(index, nil) then
							local results = callCFunctionImport(self, varg, value, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, A, B, C, D)
							coroutine.yield(index, table.unpack(results, 1, results.n))
						end
					end
					-- TODO -- self:ActivityEvent("DoneIterating", real)
				end)), self:Import(real)
			end
			-- __metatable = "The metatable is locked."
		},
		ExportMetatable = {
			__call = function(object, ...)
				self:CheckTermination()
				local real = self:GetClean(object)

				local results = if Util.isCFunction(real) then
					callCFunctionExport(self, real, ...)
				else
					callFunctionExported(self, real, ...)

				self:ActivityEvent("Call", real, table.pack(...), Util.copy(results))
				return table.unpack(results, 1, results.n)
			end,
			__index = function(object, index)
				self:CheckTermination()
				index = self:GetClean(index)

				local real = self:GetClean(object)
				local value = if real then real[index] else rawget(object, index)

				self:ActivityEvent("Get", real, index, value)
				return self:Export(value)
			end,
			__newindex = function(object, index, value)
				self:CheckTermination()
				index = self:GetClean(index)
				value = self:GetClean(value)

				local real = self:GetClean(object)
				real[index] = value

				self:ActivityEvent("Set", real, index, value)
			end,
			__iter = function(object)
				self:CheckTermination()
				self:TrackThread()

				local real = self:GetClean(object)

				-- TODO: Instead of index, value explicitly, use a vararg if it becomes possible
				--        OR if it becomes possible, correctly wrap the metamethod
				return coroutine.wrap(function(object)
					local real = self:GetClean(object)
					-- TODO -- self:ActivityEvent("Iterating", real)
					for index, value, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, A, B, C, D, OVERFLOW in real do
						assert(OVERFLOW == nil, "# of __iter results too long")
						index = self:GetClean(index)
						if not rawequal(index, nil) then
							local results = callCFunctionExport(self, varg, value, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, A, B, C, D)
							coroutine.yield(index, table.unpack(results, 1, results.n))
						end
					end
					-- TODO -- self:ActivityEvent("DoneIterating", real)
				end), real
			end
			-- __metatable = "The metatable is locked."
		}
	}

	-- Set metatable
	setmetatable(self, Sandbox)

	local baseEnv = (options and options.env) or getfenv()
	baseEnv.script = Instance.new("ModuleScript")

	self.SandboxActivity = H6x.SandboxActivity.new(self)
	self.BaseEnvironment = H6x.Environment.new(self, baseEnv)
	self.BaseRunner = H6x.Runner.new(self)

	-- Import the environment
	self:Import(self.BaseEnvironment.env)

	-- Add defaults
	self:AddDefaultSecurityRules()
	self:AddDefaultRedirects()

	return self
end

return Sandbox