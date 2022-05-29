return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local topLevel = Instance.new("Folder")
	local descendant1 = Instance.new("Folder")
	descendant1.Parent = topLevel
	local descendant2 = Instance.new("Folder")
	descendant2.Parent = descendant1

	local separateTree = Instance.new("Folder")

	sandbox:AllowInstances()
	sandbox:BlacklistTree(topLevel)

	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], topLevel), "BlacklistTree didn't blacklist top level")
	
	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant1), "BlacklistTree didn't blacklist first level descendant")

	assert(not sandbox:ExecuteString([[
		result = ...
		return result
	]], descendant2), "BlacklistTree didn't blacklist second level descendant")

	assert(sandbox:ExecuteString([[
		result = ...
		return result
	]], separateTree), "BlacklistTree blacklisted unrelated object")
end