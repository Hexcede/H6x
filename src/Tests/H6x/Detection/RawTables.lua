return function(H6x)
	local sandbox = H6x.Sandbox.new()

	local success, reason, value = sandbox:ExecuteString([[
		shared.property = 123
		
		if shared.property ~= 123 then
			return false, "Tracked get", shared.property
		end
		if rawget(shared, "property") ~= 123 then
			return false, "Rawget", rawget(shared, "property")
		end
		
		rawset(shared, "property", "abc")
		
		if shared.property ~= "abc" then
			return false, "Rawset (Tracked property check)", shared.property
		end
		if rawget(shared, "property") ~= "abc" then
			return false, "Rawset (Raw property check)", rawget(shared, "property")
		end
		
		return true
	]])
	
	assert(success, not success and string.format("Sandbox detected using: %s Value: %s", reason, tostring(value)) or "")
end