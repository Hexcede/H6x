return function(H6x)
	local sandbox = H6x.Sandbox.new({
		NoRedirectorDefaults = true
	})
	
	sandbox:AllowInstances()
	
	local dict = sandbox:Import({
		[workspace] = game
	})
	local array = sandbox:Import({
		game
	})

	assert(sandbox:ExecuteFunction(function()
		return function(...)
			for index, value in pairs(...) do
				return index == workspace and value == game
			end
			return false
		end
	end)(dict), "pairs did not loop over table.")

	assert(sandbox:ExecuteFunction(function()
		return function(...)
			for index, value in ipairs(...) do
				return index == 1 and value == game
			end
			return false
		end
	end)(array), "ipairs did not loop over array.")
end