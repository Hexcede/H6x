return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local success, typeName = sandbox:ExecuteString([[
		return typeof(game) == "Instance", typeof(game)
	]])
	
	assert(success, string.format("typeof is returning %s for instances", typeName))
end