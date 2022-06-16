return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:SetTimeout(0.05)
	local success, result = pcall(function()
		return sandbox:ExecuteFunction(function()
			task.wait(0.1)
			return true
		end)
	end)
	assert(success and result, "Sandbox terminated due to timeout when it should not have.")
end