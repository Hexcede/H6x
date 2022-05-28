local H6x = require(script.Parent:WaitForChild("H6x"))
local Logger = require(script.Parent:WaitForChild("Logger"))

local Testing = {}

-- TODO: Replace test structure with TestEZ & rewrite tests

-- Fast mode is used for security checks
--  Currently only the Termination check is skipped in fast mode since its the only one that waits
function Testing:RunTests(noLogs, fastMode, ...)
	local Tests = script.Parent:WaitForChild("Tests")

	local testsList = {Tests}
	
	local runningTests = 0
	local thread = coroutine.running()

	local failed = false
	while testsList[1] do
		for _, test in ipairs(table.remove(testsList, 1):GetChildren()) do
			if test:IsA("ModuleScript") then
				Logger:Log("TEST", 2, "Running test:", test:GetFullName())
				
				runningTests += 1
				task.spawn(function(...)
					-- Run the test function and pass test arguments
					local success, err = xpcall(require(test), function(err)
						local success, msg = pcall(debug.traceback, err, 3)

						if success then
							return msg
						else
							return debug.traceback("Error occured, no output from Lua.", 2)
						end
					end, H6x, fastMode, ...)

					if not success then
						task.spawn(Logger.Error, Logger, string.format("An error occured while running test %s:\n\t%s", test:GetFullName(), err))
						--warn(LOG_PREFIX, string.format("An error occured while running test %s:\n\t%s", test:GetFullName(), err))
						failed = true
					end
					
					runningTests -= 1
					if runningTests <= 0 then
						if coroutine.status(thread) == "suspended" then
							coroutine.resume(thread)
						end
					end

					--if not noLogs then
					--	Logger:Log("TEST", 1, "Test succeeded:", test:GetFullName())
					--end
				end, ...)
			elseif test:IsA("Folder") then
				table.insert(testsList, 1, test)
			end
		end
	end
	
	if runningTests > 0 then
		coroutine.yield()
	end

	if not failed then
		if not noLogs then
			Logger:Log("TEST", 1, "All tests passed.")
		end
		return true
	end

	if not noLogs then
		task.spawn(Logger.Error, Logger, "SOME TESTS FAILED.")
	end
	return false
end

function Testing:SecurityCheck(...)
	if not self:RunTests(true, true, ...) then
		Logger:Notice("H6x security check failed! It may be unsafe to use H6x features. Please create a bug report and include all above logs.")
		--error(H6x)
		return false
	end
	return true
end

return Testing