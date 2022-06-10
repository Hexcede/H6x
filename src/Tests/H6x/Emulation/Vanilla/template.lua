return function(H6x)
	local sandbox = H6x.Sandbox.Vanilla.new()

	sandbox:AddRule({
		Rule = "Redirect";
		Mode = "ByReference";
		Target = print;
		Replacement = function()end;
	})
	sandbox:ExecuteString([[
		
	]])
end