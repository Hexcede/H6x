return function(H6x)
	local sandbox = H6x.Sandbox.new({
		NoRedirectorDefaults = true
	})
	
	sandbox:AllowInstances()
	
	local dict = sandbox:Poison({
		[workspace] = game
	})
	
	local array = sandbox:Poison({
		game
	})
	
	-- sandbox:RedirectorDefaults()

	assert(sandbox:ExecuteString([[
		return function(...)
			for index, value in pairs(...) do
				return index == workspace and value == game
			end
			return false
		end
	]])(dict), "pairs did not loop over table.")

	assert(sandbox:ExecuteString([[
		return function(...)
			for index, value in ipairs(...) do
				return index == 1 and value == game
			end
			return false
		end
	]])(array), "ipairs did not loop over array.")
end