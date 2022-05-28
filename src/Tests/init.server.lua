local H6x = require(script.Parent)

-- Run basic tests
-- Some do their own form of security validation
local isSafeToUse = H6x.Testing:SecurityCheck()
if not isSafeToUse then
	H6x.Logger:Notice("Security check failed from test runner! It isn't gauranteed that code will run correctly, and security issues may result.")
end

-- Run all tests again, without skipping any time based tests
H6x.Testing:RunTests()