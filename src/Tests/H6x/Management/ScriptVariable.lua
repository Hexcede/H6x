return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	assert(sandbox:ExecuteFunction(function()
		return script:IsA("BaseScript") -- Script is not a module
	end), "Script variable was not redirected via runner")
	
	sandbox:SetScript(Instance.new("Folder"))

	assert(sandbox:ExecuteFunction(function()
		return script:IsA("Folder") -- Script is a folder
	end), "Script variable was not redirected via SetScript")
end