return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	assert(sandbox:ExecuteString([[
		return game
	]]), "Failed to access 'game' prior to block")

	assert(sandbox:ExecuteString([[
		return game:GetService("RunService")
	]]), "Failed to access 'RunService' prior to block")

	assert(sandbox:ExecuteString([[
		return ...
	]], game) == game, "Failed to access 'game' from input args prior to block")
	
	sandbox:DenyInstances()

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