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

	assert(not sandbox:ExecuteFunction(function()
		return game or workspace
	end), "Failed to blacklist 'game or workspace'")

	assert(not sandbox:ExecuteFunction(function()
		return Instance.new("StringValue")
	end), "Failed to blacklist 'StringValue'")

	assert(sandbox:ExecuteFunction(function()
		return Instance.new("Model")
	end), "Failed to create 'Model'")

	assert(sandbox:ExecuteFunction(function()
		return Instance.new("Folder")
	end), "Failed to create 'Folder'")

	assert(sandbox:ExecuteFunction(function()
		return Instance.new("Script")
	end), "Failed to create 'Script'")

	assert(sandbox:ExecuteFunction(function()
		return Instance.new("Part")
	end), "Failed to create 'Part'")
end