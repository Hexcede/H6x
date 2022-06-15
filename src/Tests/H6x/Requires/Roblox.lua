return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	sandbox:SetRequireMode("roblox")

	assert((sandbox:ExecuteFunction(function(...)
		return pcall(require, ...)
	end, script:Clone())), "Require failed when requires are Roblox-like.")
end