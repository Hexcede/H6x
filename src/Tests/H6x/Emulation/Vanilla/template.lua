return function(H6x)
	local sandbox = H6x.Sandbox.Vanilla.new()

	sandbox:Redirect(print, function()end)
	sandbox:ExecuteString([[
		
	]])
end