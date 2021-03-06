return function(H6x, fastMode)
	if fastMode then
		return
	end
	
	local sandbox = H6x.Sandbox.new()
	
	task.spawn(function()
		sandbox:ExecuteFunction(function()
			thread = coroutine.running()
			local a = 0
			while true do
				a += 1
				task.wait(0.25)
			end
		end)
	end)
	
	task.wait(0.5)
	
	local thread = sandbox.BaseEnvironment.env.thread
	assert(thread, "Couldn't get the sandbox thread (Bug?)")
	
	sandbox:Terminate()
	
	task.wait(0.5)
	
	-- TODO: Actually test if the thread terminated
	assert(coroutine.status(thread) == "dead", "Terminate didn't kill the thread")
	
	assert(not pcall(function()
		sandbox:ExecuteStirng(function()
			return print
		end)
	end), "New code ran after termination")
end