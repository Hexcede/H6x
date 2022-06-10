return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local topLevel = Instance.new("Folder")
	local descendant1 = Instance.new("Folder")
	descendant1.Parent = topLevel
	local descendant2 = Instance.new("Folder")
	descendant2.Parent = descendant1

	local separateTree = Instance.new("Folder")

	sandbox:DenyInstances()
	sandbox:AddRule({
		Rule = "Allow";
		Mode = "IsDescendantOfInclusive";
		Order = -2;
		Target = topLevel;
	})

	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], topLevel), "Didn't allow top level")
	
	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant1), "Didn't allow first level descendant")

	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant2), "Didn't allow second level descendant")

	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], separateTree), "Allowed unrelated object")
end