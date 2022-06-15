return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:DenyInstances()

	local allowRule = sandbox:AddRule({
		Rule = "Allow";
		Mode = "ByReference";
		Order = -1;
		Target = game;
	})
	assert(sandbox:ExecuteFunction(function()
		return game
	end), "Didn't allow 'game' when it was supposed to be")
	assert(not sandbox:ExecuteFunction(function()
		return workspace
	end), "Allowed 'workspace' when it wasn't supposed to be")
	sandbox:RemoveRule(allowRule)

	allowRule = sandbox:AddRule({
		Rule = "Allow";
		Mode = "ByReference";
		Order = -1;
		Target = workspace;
	})
	assert(sandbox:ExecuteFunction(function()
		return workspace
	end), "Didn't allow 'workspace' when it was supposed to be")
	assert(not sandbox:ExecuteFunction(function()
		return game
	end), "Allowed 'game' when it wasn't supposed to be")
	sandbox:RemoveRule(allowRule)
	
	local folder = Instance.new("Folder")
	allowRule = sandbox:AddRule({
		Rule = "Allow";
		Mode = "ByReference";
		Order = -1;
		Target = folder;
	})
	assert(sandbox:ExecuteFunction(function(...)
		return ...
	end, folder), "Didn't allow 'Folder' when it was supposed to be")
	sandbox:RemoveRule(allowRule)
end