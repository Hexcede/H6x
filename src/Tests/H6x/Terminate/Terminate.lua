return function(H6x, fastMode)
	if fastMode then
		return
	end
	
	local sandbox = H6x.Sandbox.new()
	
	sandbox:AllowInstances()
	
	task.spawn(function()
		sandbox:ExecuteString([[
			thread = coroutine.running()
			local a = 0
			while true do
				a += 1
				wait(0.25)
			end
		]])
	end)
	
	wait(0.5)
	
	local thread = sandbox.BaseEnvironment.env.thread
	assert(thread, "Couldn't get the sandbox thread (Bug?)")
	
	sandbox:Terminate()
	
	wait(0.5)
	
	-- TODO: Actually test if the thread terminated
	assert(coroutine.status(thread) == "dead", "Terminate didn't kill the thread")
	
	assert(not pcall(function()
		sandbox:ExecuteStirng([[
			return game
		]])
	end), "New code ran after termination")
	
	sandbox:Unterminate()
	
	assert(sandbox:ExecuteString([[
		return game
	]]), "Unterminate did not unterminate the sandbox")
end