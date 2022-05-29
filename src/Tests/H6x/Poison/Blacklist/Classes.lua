return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	sandbox:BlacklistClassName("TeleportService")
	sandbox:BlacklistClass("BasePart")
	
	assert(sandbox:ExecuteString([[
		return game
	]]), "Class blacklist blacklisted incorrect class")

	assert(not sandbox:ExecuteString([[
		return game:GetService("TeleportService")
	]]), "Specific ClassName blacklist failure")
	
	assert(not sandbox:ExecuteString([[
		return Instance.new("Part")
	]]), "Class type blacklist failure")
end