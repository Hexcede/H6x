return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:BlacklistType("Instance")

	sandbox:ExceptReference(game)
	assert(sandbox:ExecuteString([[
		return game
	]]), "Didn't except 'game' from test blacklist")
	assert(not sandbox:ExecuteString([[
		return workspace
	]]), "Excepted 'workspace' from test blacklist when it wasn't supposed to be")
	sandbox:ForgetReference(game) -- Clear blacklist entry (Removes the exception)

	sandbox:ExceptReference(workspace)
	assert(sandbox:ExecuteString([[
		return workspace
	]]), "Didn't except 'workspace' from test blacklist")
	assert(not sandbox:ExecuteString([[
		return game
	]]), "Excepted 'game' from test blacklist when it wasn't supposed to be")
	sandbox:ForgetReference(workspace) -- Clear blacklist entry (Removes the exception)
	
	local folder = Instance.new("Folder")
	sandbox:ExceptReference(folder)
	assert(sandbox:ExecuteString([[
		return ...
	]], folder), "Didn't except 'workspace' from test blacklist")
end