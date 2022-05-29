return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	assert(sandbox:ExecuteString([[
		return script:IsA("BaseScript") -- Script is not a module
	]]), "Script variable was not redirected via runner")
	
	sandbox:SetScript(Instance.new("Folder"))

	assert(sandbox:ExecuteString([[
		return script:IsA("Folder") -- Script is a folder
	]]), "Script variable was not redirected via SetScript")
	
	sandbox.BaseRunner.ScriptObject.Disabled = true
	
	assert(not pcall(function()
		sandbox:ExecuteString("return")
	end), "Script ran when disabled")

	sandbox.BaseRunner.ScriptObject.Disabled = false

	assert((pcall(function()
		sandbox:ExecuteString("return")
	end)), "Script didn't run after being enabled")
end