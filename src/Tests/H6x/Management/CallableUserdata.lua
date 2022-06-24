return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local userdata = newproxy(true)
	local metatable = getmetatable(userdata)

	-- Ensure that calling userdatas works as intended
	metatable.__call = function(self, arg)
		return arg
	end
	assert(sandbox:ExecuteFunction(function(userdata)
		return userdata(123)
	end, userdata) == 123, "Called userdata did not return correct results.")

	-- Ensure that the sandbox cannot circumvent sandbox rules
	metatable.__call = function()
		return game
	end
	sandbox:ExecuteFunction(function(userdata)
		assert(not userdata(), "Sandbox accessed disallowed object from callable userdata.")
	end, userdata)

	-- Ensure activity logging works as expected
	H6x.Logger:Debug(sandbox:GenerateActivityReport("h6x"))
end