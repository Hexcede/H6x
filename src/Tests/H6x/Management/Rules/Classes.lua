return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	sandbox:AddRule({
		Rule = "Block";
		Mode = "ClassEquals";
		Target = "TeleportService";
	})
	sandbox:AddRule({
		Rule = "Block";
		Mode = "IsA";
		Target = "BasePart";
	})
	
	assert(sandbox:ExecuteFunction(function()
		return game
	end), "Class blacklist blacklisted incorrect class")

	assert(not sandbox:ExecuteFunction(function()
		return game:GetService("TeleportService")
	end), "Specific ClassName blacklist failure")
	
	assert(not sandbox:ExecuteFunction(function()
		return Instance.new("Part")
	end), "Class type blacklist failure")
end