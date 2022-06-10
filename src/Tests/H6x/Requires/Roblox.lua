return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	sandbox:SetRequireMode("roblox")

	assert((sandbox:ExecuteString([[
		return pcall(require, ...)
	]], script:Clone())), "Require failed when requires are Roblox-like.")
end