return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	local thread = coroutine.wrap(function()
		sandbox:ExecuteString([[
			coroutine.yield(true)
		]])
		
		error("Executor passed after permanent yield", 2)
	end)()
end