return function(H6x)
	local sandbox = H6x.Sandbox.new()

	assert(sandbox:ExecuteFunction(function()
		return true
	end), "Failed to return (true)")
	assert(sandbox:ExecuteFunction(function()
		return false
	end) == false, "Failed to return (false)")
end