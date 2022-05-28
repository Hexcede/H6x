return function(H6x)
	local sandbox = H6x.Sandbox.new()

	assert(sandbox:ExecuteString([[
		return game
	]]), "Failed to access 'game' prior to test blacklist")

	assert(sandbox:ExecuteString([[
		return game:GetService("RunService")
	]]), "Failed to access 'RunService' prior to test blacklist")

	assert(sandbox:ExecuteString([[
		return ...
	]], game) == game, "Failed to access 'game' from input args prior to test blacklist")
	
	sandbox:BlacklistType("Instance")

	assert(not sandbox:ExecuteString([[
		return ...
	]], game), "Accessed 'game' from input args")

	assert(not sandbox:ExecuteString([[
		return game
	]]), "Accessed 'game'")
	
	assert(not sandbox:ExecuteString([[
		return workspace
	]]), "Accessed 'workspace'")
	
	assert(not sandbox:ExecuteString([[
		return Instance.new("Folder")
	]]), "Accessed 'Instance.new()'")
end