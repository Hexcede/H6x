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
	
	assert(not sandbox:ExecuteFunction(function()
		return require
	end), "Accessed require")

	assert(sandbox:ExecuteFunction(function()
		return script.Name == "FakeScript"
	end), "Script variable wasn't sandboxed")
	
	local success, access = pcall(function()
		return sandbox:ExecuteFunction(function(...)
			local success, H6x = pcall(function(...)
				globalH6x = ...
				return globalH6x
			end, ...)
			return success and H6x
		end, H6x) and true or false
	end)
	assert(not success or not access, "Accessed H6x module (Security)")

	success, access = pcall(function()
		return sandbox:ExecuteFunction(function(...)
			return ...
		end, H6x) and true or false
	end)
	assert(not success or not access, "Accessed H6x module directly (Security)")

	assert(sandbox.Terminated, "Did not terminate sandbox after accessing H6x module.")

	-- Create fresh sandbox (old one should be terminated)
	sandbox = H6x.Sandbox.new()

	success, access = pcall(function()
		return sandbox:ExecuteFunction(function(...)
			local success, sandbox = pcall(function(...)
				globalSandbox = ...
				return globalSandbox
			end, ...)
			return success and sandbox
		end, sandbox) and true or false
	end)
	assert(not success or not access, "Accessed Sandbox inside Sandbox (Security)")
end