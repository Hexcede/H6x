return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local topLevel = Instance.new("Folder")
	local descendant1 = Instance.new("Folder")
	descendant1.Parent = topLevel
	local descendant2 = Instance.new("Folder")
	descendant2.Parent = descendant1

	local separateTree = Instance.new("Folder")

	sandbox:AllowInstances()
	sandbox:AddRule({
		Rule = "Block";
		Mode = "IsDescendantOfInclusive";
		Order = -2;
		Target = topLevel;
	})

	assert(not sandbox:ExecuteFunction(function(...)
		result = ...
		return result
	end, topLevel), "Didn't block top level")
	
	assert(not sandbox:ExecuteFunction(function(...)
		result = ...
		return result
	end, descendant1), "Didn't block first level descendant")

	assert(not sandbox:ExecuteFunction(function(...)
		result = ...
		return result
	end, descendant2), "Didn't block second level descendant")

	assert(sandbox:ExecuteFunction(function(...)
		result = ...
		return result
	end, separateTree), "Blocked unrelated object")
end