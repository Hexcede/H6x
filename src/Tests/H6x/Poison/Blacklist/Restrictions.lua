return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:Restrict(game)
	
	assert(not sandbox:ExecuteString([[
		local success, game = pcall(function()
			return game
		end)
		return success and game
	]]), "Value restriction failed")
end