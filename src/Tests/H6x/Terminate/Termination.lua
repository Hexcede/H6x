return function(H6x, fastMode)
	local sandbox = H6x.Sandbox.new()
	
	task.spawn(function()
		sandbox:ExecuteFunction(function()
			thread = coroutine.running()
			local a = 0
			while true do
				a += 1
				task.wait()
			end
		end)
	end)

	local thread = sandbox.BaseEnvironment.env.thread
	assert(thread, "Couldn't get the sandbox thread (Bug?)")

	sandbox:Terminate()

	-- TODO: Actually test if the thread terminated
	assert(coroutine.status(thread) == "dead", "Terminate didn't kill the thread.")

	assert(not sandbox:ExecuteFunction(function()
		return true
	end), "New code ran after termination.")
end