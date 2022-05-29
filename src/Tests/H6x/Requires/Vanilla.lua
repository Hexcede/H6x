return function(H6x)
	local sandbox = H6x.Sandbox.new()

	sandbox:SetRequireMode("vanilla")

	sandbox:AddModule("ABC", 123)
	sandbox:AddModule("DEF", 456)

	assert((sandbox:ExecuteString([[
		return require "ABC" == 123 and require "DEF" == 456
	]], script)), "Require failed when requires are vanilla-emulated.")
end