-- Localize globals (To prevent usage of sandboxed versions)
local coroutine = coroutine
local debug = debug
local getfenv = getfenv
local setfenv = setfenv
local table = table
local error = error
local xpcall = xpcall
local pcall = pcall
local wait = wait
local print = print
local tostring = tostring
-- Simple trick to prevent print's root fenv from becoming the caller (By getting rid of the call stack)
-- This uses extra memory for the thread so its not an ideal solution

-- As of update 476 the below is no longer necessary

--local print = coroutine.wrap(function()
--	while true do
--		print(coroutine.yield())
--	end
--end)
--print() -- Start print thread

-- Return a wrapped coroutine which generates runner coroutines
return coroutine.wrap(function()
	while true do
		-- Track the thread of the caller (so we can resume it when results are ready)
		local callingThread
		-- Track the thread of the runner coroutine
		local runnerThread
		local runner = coroutine.wrap(function()
			runnerThread = coroutine.running()
			
			local callback, args = coroutine.yield()
			local sandboxEnvironment = getfenv(callback)
			
			-- Apply the environment of the callback function to rhe root of the module & the coroutine body (To prevent sandbox escapes)
			setfenv(0, sandboxEnvironment)
			setfenv(1, sandboxEnvironment)

			local parentThread = coroutine.running()
			
			-- Spawn a sub thread for running the callback
			local subThread = coroutine.create(function(...)
				return (function(success, ...)
					--wait()
					-- Save the results
					local results = table.pack(...)
					if parentThread then
						-- Check if the parent thread is waiting for our results and resume it if it is
						if coroutine.status(parentThread) == "suspended" then
							coroutine.resume(parentThread, success, results)
							return
						end
					end
					-- Return the results
					return success, results
				end)(xpcall(callback, function(err, ...)
					local success, msg = pcall(debug.traceback, err, 3)

					if success then
						return msg
					else
						return debug.traceback("Error occured, no output from Lua.", 2)
					end
				end, ...))
			end)
			
			-- Resume the sub thread and pass arguments
			local resumed, success, results = coroutine.resume(subThread, table.unpack(args))
			
			-- If the thread failed to be ran
			if not resumed then
				results = {success}
				success = resumed
			end
			
			-- If the sub thread isn't dead we want to wait for it to complete
			if coroutine.status(subThread) ~= "dead" then
				-- Wait for results
				success, results = coroutine.yield()
			end
			
			-- Return results
			parentThread = nil
			if callingThread then
				if coroutine.status(callingThread) == "suspended" then
					-- Pass results back to the calling thread
					coroutine.resume(callingThread, success, results)
					return
				end
			end
			-- Return the results
			return success, results
		end)
		runner()
		
		-- Yield the wrapped generator function
		coroutine.yield(function(...)
			-- Set the calling thread
			callingThread = coroutine.running()
			-- Start the runner
			local success, results = runner(...)
			-- Wait for runner thread to finish
			if success == nil then
				success, results = coroutine.yield()
			end

			-- Throw the error
			if not success then
				return error(table.unpack(results), 2)
			end
			
			-- Unpack results
			return table.unpack(results)
		end, runnerThread)
	end
end)