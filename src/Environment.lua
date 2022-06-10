local H6x = require(script.Parent:WaitForChild("H6x"))
local Logger = require(script.Parent:WaitForChild("Logger"))
local Util = require(script.Parent:WaitForChild("Util"))

local Environment = {}
Environment.__index = Environment

function Environment:Apply(target)
	if type(target) == "number" and target > 0 then
		target += 1
	end
	return setfenv(target, self.env)
end

function Environment.new(sandbox, subEnvironment)
	assert(sandbox, "Environment cannot be created without a sandbox.")

	if sandbox.Environments[subEnvironment] then
		return sandbox.Environments[subEnvironment]
	end

	local environment = setmetatable({
		Sandbox = sandbox,
		env = sandbox:Import(setmetatable(Util.copy(subEnvironment), {
			__index = subEnvironment;
			__metatable = getmetatable(subEnvironment);
		})),
		subenv = subEnvironment
	}, Environment)
	
	sandbox.Environments[subEnvironment] = environment
	sandbox.Environments[environment.env] = environment
	return environment
end

return Environment