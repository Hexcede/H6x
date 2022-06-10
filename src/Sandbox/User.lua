local Sandbox = require(script.Parent:WaitForChild("Sandbox"))

local User = {}

--[=[
	Creates a sandbox configured for running user scripts, without access to any Roblox instances.
]=]
function User.new(options)
	local sandbox = Sandbox.new(options)
	sandbox:SetRequireMode("vanilla")
	return sandbox
end

return User