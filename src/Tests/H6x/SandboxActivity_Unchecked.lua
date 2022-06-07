return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:ExecuteFunction(function()
		abc = function(a, b)
			return b, a
		end
		b, a = abc({ABC = abc}, 2)
		a.ABC(4, 5)
		a:ABC(8)
	end)
	H6x.Logger:Debug(sandbox:GenerateActivityReport("h6x"))
end