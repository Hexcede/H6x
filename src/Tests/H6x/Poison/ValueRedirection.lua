return function(H6x)
	local sandbox = H6x.Sandbox.new()
	
	sandbox:Redirect("someReallySpecificString", "someOtherString")
	
	-- Note: Since values can't be accessed unless they get exposed to the sandbox somehow the value is put in the globals so it'll get filtered when its read back
	
	assert(sandbox:ExecuteString([[
		globalThing = "someReallySpecificString"
		return globalThing
	]]) == "someOtherString", "Didn't redirect value directly")

	assert(sandbox:ExecuteString([[
		globalThing = "someNotVerySpecificString"
		return globalThing
	]]) == "someNotVerySpecificString", "Redirected a value that shouldn't have been redirected")
	
	sandbox:RedirectHandle("someReallySpecificString2.0", function(sandbox, value)
		assert(value == "someReallySpecificString2.0", "Redirection handle redirected the wrong thing")
		return "someOtherString"
	end)

	assert(sandbox:ExecuteString([[
		globalThing = "someReallySpecificString2.0"
		return globalThing
	]]) == "someOtherString", "Didn't redirect value via handle")

	assert(sandbox:ExecuteString([[
		globalThing = "someNotVerySpecificString"
		return globalThing
	]]) == "someNotVerySpecificString", "Redirected a value that shouldn't have been redirected")
end