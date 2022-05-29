return function(H6x, fastMode)
	local sandbox = H6x.Sandbox.new()

	sandbox:AllowInstances()
	
	task.spawn(function()
		sandbox:ExecuteString([[
			thread = coroutine.running()
			local a = 0
			while true do
				a += 1
				task.wait()
			end
		]])
	end)

	local thread = sandbox.BaseEnvironment.env.thread
	assert(thread, "Couldn't get the sandbox thread (Bug?)")
	
	if not fastMode then
		task.wait(1)
	end
	
	sandbox:Terminate()

	-- TODO: Actually test if the thread terminated
	assert(coroutine.status(thread) == "dead", "Terminate didn't kill the thread.")

	assert(not pcall(function()
		sandbox:ExecuteStirng([[
			return game
		]])
	end), "New code ran after termination.")

	sandbox:Unterminate()

	assert(sandbox:ExecuteString([[
		return game
	]]), "Unterminate did not allow the sandbox to be reused.")
end