return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	sandbox:SetRequireMode("disabled")

	assert(not (sandbox:ExecuteString([[
		return pcall(require, ...)
	]], script)), "Require succeeded when requires are disabled.")
end