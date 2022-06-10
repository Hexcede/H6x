return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:AllowInstances()
	local rule = sandbox:AddRule({
		Rule = "Redirect";
		Mode = "ClassEquals";
		Target = "Folder";
		Replacement = "A folder instance was here.";
	})
	
	-- Note: Since values can't be accessed unless they get exposed to the sandbox somehow the value is put in the globals so it'll get filtered when its read back
	
	assert(sandbox:ExecuteString([[
		globalThing = Instance.new("Folder")
		return globalThing
	]]) == rule.Replacement, "Didn't redirect value directly")

	assert(sandbox:ExecuteString([[
		globalThing = Instance.new("Model")
		return globalThing
	]]):IsA("Model"), "Redirected a value that shouldn't have been redirected")
	
	sandbox:RemoveRule(rule)
	sandbox:AddRule({
		Rule = "Inject";
		Mode = "ClassEquals";
		Target = "Folder";
		Callback = function(value)
			assert(value:IsA("Folder"), "Redirection handle redirected the wrong thing")
			return "Injected"
		end
	})

	assert(sandbox:ExecuteString([[
		globalThing = Instance.new("Folder")
		return globalThing
	]]) == "Injected", "Didn't inject at value")

	assert(sandbox:ExecuteString([[
		globalThing = Instance.new("Model")
		return globalThing
	]]) ~= "Injected", "Injected at a value that shouldn't have been")

	assert(sandbox:ExecuteString([[
		return Instance.new("Folder")
	]]) == "Injected", "Didn't inject at value when returning directly")
end