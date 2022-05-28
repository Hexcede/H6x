local runnerBindable = script:WaitForChild("RunnerBindable")
local runner = require(script:WaitForChild("Runner", math.huge))

runnerBindable.OnInvoke = function(...)
	script.Parent = nil

	runnerBindable.OnInvoke = runner
	return runner(...)
end