return function(H6x)
	local sandbox = H6x.Sandbox.new({
		NoRedirectorDefaults = true
	})
	
	-- Note: pairs & ipairs work as intended in this build without the redirector defaults
	
	local dict = sandbox:Poison({
		[workspace] = game
	})
	
	local array = sandbox:Poison({
		game
	})
	
	sandbox:RedirectorDefaults()

	assert(sandbox:ExecuteString([[
		return function(...)
			for index, value in pairs(...) do
				return index == workspace and value == game
			end
			return false
		end
	]])(dict), "Redirector defaults didn't resolve pairs issue")

	assert(sandbox:ExecuteString([[
		return function(...)
			for index, value in ipairs(...) do
				return index == 1 and value == game
			end
			return false
		end
	]])(array), "Redirector defaults didn't resolve ipairs issue")
end