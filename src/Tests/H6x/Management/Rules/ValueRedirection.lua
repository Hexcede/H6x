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
	
	assert(sandbox:ExecuteFunction(function()
		globalThing = Instance.new("Folder")
		return globalThing
	end) == rule.Replacement, "Didn't redirect value directly")

	assert(sandbox:ExecuteFunction(function()
		globalThing = Instance.new("Model")
		return globalThing
	end):IsA("Model"), "Redirected a value that shouldn't have been redirected")
	
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

	assert(sandbox:ExecuteFunction(function()
		globalThing = Instance.new("Folder")
		return globalThing
	end) == "Injected", "Didn't inject at value")

	assert(sandbox:ExecuteFunction(function()
		globalThing = Instance.new("Model")
		return globalThing
	end) ~= "Injected", "Injected at a value that shouldn't have been")

	assert(sandbox:ExecuteFunction(function()
		return Instance.new("Folder")
	end) == "Injected", "Didn't inject at value when returning directly")
end