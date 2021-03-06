return function(H6x)
	do
		-- Try to iterate on a table. If this fails, the feature is disabled.
		-- TODO: Remove this
		if not pcall(function()
			for _ in {} do end
		end) then
			return
		end
	end

	local sandbox = H6x.Sandbox.new()

	local testTable = {
		2,
		"abc"
	}

	-- Create a userdata which iterates over the table with pairs
	local iterable = newproxy(true)
	local meta = getmetatable(iterable)
	meta.__iter = function(self)
		return pairs(testTable)
	end
	meta.__metatable = "The metatable is locked."

	-- Test iteration
	local iterCount = 0
	sandbox:ExecuteFunction(function(iterable)
		for x, y in iterable do
			if x == 1 then
				assert(y == 2, string.format("The value at index 1 was not 2, it was %s.", tostring(y)))
			elseif x == 2 then
				assert(y == "abc", string.format("The value at index 2 was not \"abc\", it was %s.", tostring(y)))
			end
			iterCount += 1
		end
	end, iterable)
	assert(iterCount == #testTable, "Didn't iterate over all elements.")

	-- Make sure values are not leaked
	testTable = {
		abc = game,
		[game] = "abc"
	}
	local iterCount = 0
	sandbox:ExecuteFunction(function(iterable)
		for a, b in iterable do
			assert(typeof(a) ~= "Instance", "Instance leaked to sandbox through __iter as key.")
			assert(typeof(b) ~= "Instance", "Instance leaked to sandbox through __iter as value.")
			assert(typeof(a) ~= "nil", "nil was a key in the sandbox iterator, but it should be skipped.")
			iterCount += 1
		end
	end, iterable)
	assert(iterCount == 1, string.format("Iterated over too many or too few elements. Expected one iteration, but %d iterations occurred.", iterCount))

	-- Make sure multiple values can be returned from an iterator
	meta.__iter = function(self)
		return string.gmatch("abc 123 EFG", "(%w+) (%d+) (%w+)")
	end
	sandbox:ExecuteFunction(function(iterable)
		for a, b, c in iterable do
			assert(a == "abc", "The first value was not \"abc\".")
			assert(b == "123", "The second value was not \"123\".")
			assert(c == "EFG", "The third value was not \"EFG\".")
		end
	end, iterable)
end