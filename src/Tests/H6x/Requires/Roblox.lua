return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	sandbox:ExceptReference(script)
	sandbox:SetRequireMode("roblox")

	assert((sandbox:ExecuteString([[
		return pcall(require, ...)
	]], script)), "Require failed when requires are Roblox-like.")
end