return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:AllowInstances()
	sandbox:AddRule({
		Rule = "Terminate";
		Mode = "ByReference";
		Target = game;
	})
	assert(not sandbox:ExecuteString([[
		local success, game = pcall(function()
			return game
		end)
		return success and game
	]]), "Did not block game")
end