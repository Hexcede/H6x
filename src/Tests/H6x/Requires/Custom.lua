return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:SetRequireMode(function(module)
		if module == "ABC" then
			return 123
		elseif module == "DEF" then
			return 456
		end
		return false 
	end)

	assert(sandbox:ExecuteFunction(function()
		return require("ABC") == 123
	end), "Custom require mode is not working (1)")
	assert(sandbox:ExecuteFunction(function()
		return require("DEF") == 456
	end), "Custom require mode is not working (2)")
	assert(sandbox:ExecuteFunction(function()
		return require("GHI") == false
	end), "Custom require mode is not working (3)")
end