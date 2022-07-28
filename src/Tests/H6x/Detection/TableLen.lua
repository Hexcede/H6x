return function(H6x)
	local sandbox = H6x.Sandbox.new()
	assert(sandbox:ExecuteFunction(function(tab)
		return #tab
	end, {1, 2, 3}) == 3, "Table length does not match.")
end