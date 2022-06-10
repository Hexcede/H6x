return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:DenyInstances()

	sandbox:AddRule({ -- Only Model classes, but, not things like Workspace which extend Model
		Rule = "Allow";
		Mode = "ClassEquals";
		Target = "Model";
	})
	sandbox:AddRule({
		Rule = "Allow";
		Mode = "IsA";
		Target = "Folder";
	})
	sandbox:AddRule({
		Rule = "Allow";
		Mode = "IsA";
		Target = "BasePart";
	})
	sandbox:AddRule({
		Rule = "Allow";
		Mode = "IsA";
		Target = "LuaSourceContainer";
	})

	assert(not sandbox:ExecuteString([[
		return game or workspace
	]]), "Failed to blacklist 'game or workspace'")

	assert(not sandbox:ExecuteString([[
		return Instance.new("StringValue")
	]]), "Failed to blacklist 'StringValue'")

	assert(sandbox:ExecuteString([[
		return Instance.new("Model")
	]]), "Failed to create 'Model'")

	assert(sandbox:ExecuteString([[
		return Instance.new("Folder")
	]]), "Failed to create 'Folder'")

	assert(sandbox:ExecuteString([[
		return Instance.new("Script")
	]]), "Failed to create 'Script'")

	assert(sandbox:ExecuteString([[
		return Instance.new("Part")
	]]), "Failed to create 'Part'")
end