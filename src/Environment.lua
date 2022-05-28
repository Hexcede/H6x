local H6x = require(script.Parent:WaitForChild("H6x"))
local Logger = require(script.Parent:WaitForChild("Logger"))
local Util = require(script.Parent:WaitForChild("Util"))

return (function(Environment)
	local class = (function(Environment)
		-- A property descriptor, exactly like in JavaScript
		-- The enumerable property doesn't do anything
		function Environment:DefineProperty(property, descriptor)
			local properties = self.Properties

			properties[property] = descriptor
		end

		function Environment:DefineProperties(descriptors)
			for property, descriptor in pairs(descriptors) do
				self:DefineProperty(property, descriptor)
			end
		end

		function Environment:Apply(target)
			if type(target) == "number" and target > 0 then
				target += 1
			end

			return setfenv(target, self.env)
		end

		return Environment
	end)({})
	class.__index = class

	local fromEnv = {}
	local envMetatable = {
		__index = function(env, index)
			local properties, subEnvironment, sandbox = Util.unpack(fromEnv[env])

			--if DEBUG_LOGS then
			--	if VERBOSE_LOGS then
			--		print(LOG_PREFIX, "Environment __index", index)
			--	end
			--end
			Logger:Debug("env __index", index)

			local property = properties[index]
			if property then
				if property.get then
					return property:get()
				end

				return property.value
			end

			local value = subEnvironment[index]

			if sandbox then
				sandbox:ActivityEvent("GetGlobal", index, value)
			end

			return value
		end,
		__newindex = function(env, index, value)
			local properties, subEnvironment, sandbox = Util.unpack(fromEnv[env])

			local property = properties[index]
			if property then
				if property.set then
					return property:set(value)
				end

				if property.writeable and property.configurable then
					property.value = value
				end
				return
			end

			if sandbox then
				sandbox:ActivityEvent("SetGlobal", index, value)
			end

			subEnvironment[index] = value
		end,
		--__metatable = "PRIVATE METATABLE"
	}

	function Environment.new(sandbox, subEnvironment)
		local Environments = sandbox and sandbox.Environments

		local environment = Environments and Environments[subEnvironment]
		if environment then
			return environment
		end

		local properties = {}
		local env = setmetatable({}, H6x.Reflector.from(subEnvironment, envMetatable))
		local self = {
			Sandbox = sandbox,
			Properties = properties,
			env = sandbox and sandbox:Poison(env) or env,
			subenv = subEnvironment
		}

		fromEnv[env] = {properties, subEnvironment, sandbox}

		if Environments then
			Environments[subEnvironment] = self
		end
		return setmetatable(self, class)
	end

	return Environment
end)({})