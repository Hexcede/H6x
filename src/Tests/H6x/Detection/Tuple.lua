return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:ExecuteFunction(function()
		assert(select("#", nil, nil, nil) == 3, "Argument tuple size did not match (select)")
		assert(table.pack(unpack({}, 1, 3)).n == 3, "Argument tuple size did not match (table.pack)")
		
		-- Assign to global to poison
		testMulti = function(...)
			return ...
		end
		
		assert(select("#", testMulti(nil, nil, nil)) == 3, "Return tuple size did not match (select)")
	end)
end