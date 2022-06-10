return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:DenyInstances()

	local allowRule = sandbox:AddRule({
		Rule = "Allow";
		Mode = "ByReference";
		Order = -1;
		Target = game;
	})
	assert(sandbox:ExecuteString([[
		return game
	]]), "Didn't allow 'game' when it was supposed to be")
	assert(not sandbox:ExecuteString([[
		return workspace
	]]), "Allowed 'workspace' when it wasn't supposed to be")
	sandbox:RemoveRule(allowRule)

	allowRule = sandbox:AddRule({
		Rule = "Allow";
		Mode = "ByReference";
		Order = -1;
		Target = workspace;
	})
	assert(sandbox:ExecuteString([[
		return workspace
	]]), "Didn't allow 'workspace' when it was supposed to be")
	assert(not sandbox:ExecuteString([[
		return game
	]]), "Allowed 'game' when it wasn't supposed to be")
	sandbox:RemoveRule(allowRule)
	
	local folder = Instance.new("Folder")
	allowRule = sandbox:AddRule({
		Rule = "Allow";
		Mode = "ByReference";
		Order = -1;
		Target = folder;
	})
	assert(sandbox:ExecuteString([[
		return ...
	]], folder), "Didn't allow 'Folder' when it was supposed to be")
	sandbox:RemoveRule(allowRule)
end