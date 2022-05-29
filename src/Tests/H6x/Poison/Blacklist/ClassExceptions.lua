return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:Blacklist(require)
	sandbox:DenyInstances()

	-- Example of how to except certain classes
	sandbox:ExceptClassName("Model") -- Only Model classes, but, not things like Workspace which extend Model
	sandbox:ExceptClass("Folder")
	sandbox:ExceptClass("BasePart")
	sandbox:ExceptClass("LuaSourceContainer")

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