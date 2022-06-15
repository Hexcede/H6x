--[[
	 H   H  = 6 6  =   =
	 6 - 6  6 -    x   x
	 H 6 x  X 6 x   x=x
	 6 - 6  6 - 6  x   x
	 h   h  = 6 =  =   =
	======================
	 A secure and user-oriented luau sandbox
	
	- Hexcede, 2022
--]]

-- Module
local H6x = require(script:WaitForChild("H6x"))

-- Main dependencies
local Logger = require(script:WaitForChild("Logger"))
local Constants = require(script:WaitForChild("Constants"))

-- Libraries
local libraries = {
	-- Utils
	Logger = Logger;
	Constants = Constants;
	Testing = require(script:WaitForChild("Testing"));
	Util = require(script:WaitForChild("Util"));

	-- Classes
	Sandbox = require(script:WaitForChild("Sandbox"));
	Environment = require(script:WaitForChild("Environment"));
	Runner = require(script:WaitForChild("Runner"));
	Reflector = require(script:WaitForChild("Reflector"));
	SandboxActivity = require(script:WaitForChild("SandboxActivity"));
}

for index, value in pairs(libraries) do
	H6x[index] = value
end
return H6x