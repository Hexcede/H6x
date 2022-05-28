return function(H6x)
	local sandbox = H6x.Sandbox.new()

	assert(sandbox:ExecuteString([[
		return true
	]]), "Failed to return (true)")
	assert(sandbox:ExecuteString([[
		return false
	]]) == false, "Failed to return (false)")
end