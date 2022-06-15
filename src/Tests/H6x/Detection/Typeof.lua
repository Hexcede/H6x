return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	local success, typeName = sandbox:ExecuteFunction(function()
		return typeof(game) == "Instance", typeof(game)
	end)
	
	assert(success, string.format("typeof is returning %s for instances", typeName))
end