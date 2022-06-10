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

	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], topLevel), "Didn't block top level")
	
	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant1), "Didn't block first level descendant")

	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant2), "Didn't block second level descendant")

	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], separateTree), "Blocked unrelated object")
end