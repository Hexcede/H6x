return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	sandbox:SetRequireMode("disabled")

	assert(not (sandbox:ExecuteFunction(function(...)
		return pcall(require, ...)
	end, script:Clone())), "Require succeeded when requires are disabled.")
end