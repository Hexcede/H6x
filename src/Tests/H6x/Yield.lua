return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	task.spawn(function()
		sandbox:ExecuteFunction(function()
			coroutine.yield()
		end)
		error("Permanent yield was skipped.", 2)
	end)
end