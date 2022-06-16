return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local FAILED = false
	sandbox:SetTimeout(0.05)
	local depth = 0
	task.defer(function(thread)
		pcall(function()
			sandbox:ExecuteFunction(function()
				local startTime = os.clock()
				local function hangForAWhile()
					depth += 1
					task.wait()
					task.spawn(pcall, hangForAWhile)
					-- Note: Managed code is triggered by os.clock()
					while os.clock() - startTime < (sandbox.Timeout * 2 + 0.5) do end
					FAILED = true
				end
				task.spawn(pcall, hangForAWhile)
			end)
		end)
		coroutine.resume(thread)
	end, coroutine.running())
	coroutine.yield() -- Wait until the above completes
	assert(not FAILED, "Sandbox didn't terminate after the configured timeout.")
end