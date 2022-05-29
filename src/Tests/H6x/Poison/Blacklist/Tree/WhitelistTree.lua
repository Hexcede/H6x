return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local topLevel = Instance.new("Folder")
	local descendant1 = Instance.new("Folder")
	descendant1.Parent = topLevel
	local descendant2 = Instance.new("Folder")
	descendant2.Parent = descendant1

	local separateTree = Instance.new("Folder")

	sandbox:DenyInstances()
	sandbox:ExceptTree(topLevel)

	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], topLevel), "ExceptTree didn't except top level")
	
	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant1), "ExceptTree didn't except first level descendant")

	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant2), "ExceptTree didn't except second level descendant")

	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], separateTree), "ExceptTree allowed unrelated object")
end