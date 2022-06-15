return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	assert(sandbox:ExecuteFunction(function()
		return game
	end), "Failed to access 'game' prior to block")

	assert(sandbox:ExecuteFunction(function()
		return game:GetService("RunService")
	end), "Failed to access 'RunService' prior to block")

	assert(sandbox:ExecuteFunction(function(...)
		return ...
	end, game) == game, "Failed to access 'game' from input args prior to block")
	
	sandbox:DenyInstances()

	assert(not sandbox:ExecuteFunction(function(...)
		return ...
	end, game), "Accessed 'game' from input args")

	assert(not sandbox:ExecuteFunction(function()
		return game
	end), "Accessed 'game'")
	
	assert(not sandbox:ExecuteFunction(function()
		return workspace
	end), "Accessed 'workspace'")
	
	assert(not sandbox:ExecuteFunction(function()
		return Instance.new("Folder")
	end), "Accessed 'Instance.new()'")
end