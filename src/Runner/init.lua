local H6x = require(script.Parent:WaitForChild("H6x"))
local Logger = require(script.Parent:WaitForChild("Logger"))

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

return (function(Runner)
	local class = (function(Runner)
		function Runner:ExecuteFunction(callback, ...)
			local sandbox = self.Sandbox
			if sandbox then
				callback = sandbox:LoadFunction(callback)

				if sandbox.Terminated then
					return
				end
			else
				--if WARN_UNSANDBOXED_RUNNER then
				--	print(LOG_PREFIX, "Using an unsafe runner to execute a function")
				--end
				Logger:Notice("Using an unsafe runner (not sandboxed) to execute a function. Use a sandbox to silence this.")
			end

			local scriptObject = self.ScriptObject
			if scriptObject:IsA("BaseScript") then
				if scriptObject.Disabled then
					return error("Runner script is disabled", 2)
				end
			end

			local runner, thread = self.__createRunner()
			self.RunnerThread = thread

			return runner(callback, table.pack(...))
		end

		function Runner:ExecuteString(str, ...)
			if self.Sandbox then
				return self:ExecuteFunction(self.Sandbox:LoadString(str), ...)
			else
				--warn(LOG_PREFIX, "Using an unsafe runner to load a string! Use a sandbox to get rid of this warning.")
				Logger:Notice("Using an unsafe runner (not sandboxed) to execute a string. Use a sandbox to silence this.")
			end

			local callback, errMessage = loadstring(str)

			assert(callback, errMessage)
			return self:ExecuteFunction(callback, ...)
		end

		return Runner
	end)({})
	class.__index = class

	local baseRunnerScript = script:WaitForChild("ServerRunner")
	local baseLocalRunner = script:WaitForChild("LocalRunner")
	local baseRunnerModule = script:WaitForChild("Runner")
	function Runner.new(sandbox, inModule)
		-- Create a runner script for the environment
		local runnerScript = inModule and baseRunnerModule:Clone() or (RunService:IsClient() and baseLocalRunner or baseRunnerScript):Clone()

		-- Allow the script to run
		local createRunner
		if not inModule then
			-- Place the script in a runnable location and give it the runner module
			baseRunnerModule.Parent = runnerScript
			runnerScript.Parent = RunService:IsClient() and (Players.LocalPlayer:WaitForChild("PlayerScripts")) or ServerScriptService

			-- Set up the runner callback
			local bindable = runnerScript:WaitForChild("RunnerBindable")
			createRunner = function(...)
				return bindable:Invoke(...)
			end
		else
			-- Get the runner callback from the runner module
			createRunner = require(runnerScript)
		end

		local self = {
			Sandbox = sandbox,
			ScriptObject = runnerScript,
			__createRunner = createRunner
		}

		local initRunner, thread = createRunner()
		self.RunnerThread = thread

		if not inModule then
			-- Return the runner module back to H6x
			baseRunnerModule.Parent = script
		end

		-- If we're not using a sandbox this runner is unsafe, so, warn unless disabled
		if not sandbox then
			--if WARN_UNSANDBOXED_RUNNER then
			--	warn(LOG_PREFIX, "An unsafe runner was created! Consider using a sandbox for a bit of safety. Disable this message by editing the top of this script.")
			--end
			Logger:Notice("An unsafe runner was initialized. Use a sandbox to silence this.")
		-- else
			-- Redirect the script variable in the sandbox
			-- sandbox:__redirectScript(runnerScript)
		end

		-- Create a callback for the initial runner code (This sets up the runner for running sandboxed code)
		local coroutine = coroutine
		local getfenv = getfenv
		local string = string
		local table = table
		local function callback()
			--if DEBUG_LOGS then
			--	if VERBOSE_LOGS then
			--		print(LOG_PREFIX, "Runner initialized.", "\n",
			--			"\tEnvironment correctly applied:", (getfenv(0) == getfenv(1) and getfenv(0) == getfenv(2)) and "YES." or "NO. (Bug?)", "\n",
			--			"\tEnvironment:", getfenv(0), "\n",
			--			"\tSandboxed:", sandbox and "YES." or "NO.", "\n",
			--			"\tSandbox:", sandbox
			--		)
			--	end

			--	debugEnv(getfenv(0))
			--end
			-- Logger:Debug("Runner initialized.\n",
			-- 	"\tEnvironment mismatch:", (rawequal(getfenv(0), getfenv(1)) and rawequal(getfenv(0), getfenv(2))) and "NO." or "YES. (This is a BUG, potential environment leak)", "\n",
			-- 	"\tSandbox environment:", tostring(getfenv(0)), "\n",
			-- 	"\tIs sandboxed:", sandbox and "YES." or "NO.", "\n",
			-- 	"\tSandbox object:", tostring(sandbox)
			-- )
		end

		-- Apply the base environment to the callback function
		if sandbox.BaseEnvironment then
			sandbox.BaseEnvironment:Apply(callback)
		end
		-- Initialize the runner
		initRunner(callback, {})

		return setmetatable(self, class)
	end

	return Runner
end)({})