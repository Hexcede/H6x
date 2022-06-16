return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local FAILED = false
	sandbox:SetTimeout(0.05)
	task.spawn(pcall, function()
		sandbox:ExecuteFunction(function()
			local startTime = os.clock()
			-- Note: Managed code is triggered by os.clock()
			while os.clock() - startTime < (sandbox.Timeout * 2 + 0.5) do end
			FAILED = true
		end)
	end)
	assert(not FAILED, "Sandbox didn't terminate after the configured timeout.")
end