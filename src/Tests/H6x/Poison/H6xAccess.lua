return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	sandbox:BlacklistReference(require)
	sandbox:SetScript(Instance.new("Script"))
	
	assert(not sandbox:ExecuteString([[
		return require
	]]), "Accessed require")
	
	local success, access = pcall(function()
		return sandbox:ExecuteString([[
			local success, H6x = pcall(function(...)
				globalH6x = ...
				return globalH6x
			end, ...)
			return success and H6x
		]], H6x) and true or false
	end)
	assert(not success or not access, "Accessed H6x module (Security)")
	
	sandbox:Unterminate()

	local success, access = pcall(function()
		return sandbox:ExecuteString([[
			local success, sandbox = pcall(function(...)
				globalSandbox = ...
				return globalSandbox
			end, ...)
			return success and sandbox
		]], sandbox) and true or false
	end)
	assert(not success or not access, "Accessed Sandbox inside Sandbox (Security)")

	sandbox:Unterminate()
	
	assert(not sandbox:ExecuteString([[
		return script.Name == "H6x"
	]]), "Script variable wasn't sandboxed")
end