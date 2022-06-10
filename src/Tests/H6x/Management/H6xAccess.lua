return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	sandbox:AddRule({
		Rule = "Block";
		Mode = "ByReference";
		Target = require;
	})
	local fakeScript = Instance.new("Script")
	fakeScript.Name = "FakeScript"
	sandbox:SetScript(fakeScript)
	
	assert(not sandbox:ExecuteString([[
		return require
	]]), "Accessed require")

	assert(sandbox:ExecuteString([[
		return script.Name == "FakeScript"
	]]), "Script variable wasn't sandboxed")
	
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

	success, access = pcall(function()
		return sandbox:ExecuteString([[
			return ...
		]], H6x) and true or false
	end)
	assert(not success or not access, "Accessed H6x module directly (Security)")

	assert(sandbox.Terminated, "Did not terminate sandbox after accessing H6x module.")

	-- Create fresh sandbox (old one should be terminated)
	sandbox = H6x.Sandbox.new()

	success, access = pcall(function()
		return sandbox:ExecuteString([[
			local success, sandbox = pcall(function(...)
				globalSandbox = ...
				return globalSandbox
			end, ...)
			return success and sandbox
		]], sandbox) and true or false
	end)
	assert(not success or not access, "Accessed Sandbox inside Sandbox (Security)")
end