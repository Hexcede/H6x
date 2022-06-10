local Sandbox = require(script.Parent:WaitForChild("Sandbox"))

local RBXUnlimited = {}

--[=[
	Creates a new sandbox with a few sensitive services limited.
]=]
function RBXUnlimited.new(options)
	local sandbox = Sandbox.new(options)

	sandbox:AddRule({
		Rule = "Block";
		Mode = "ClassEquals";
		Target = "TeleportService";
	})
	sandbox:AddRule({
		Rule = "Block";
		Mode = "ClassEquals";
		Target = "MarketplaceService";
	})
	sandbox:AddRule({
		Rule = "Block";
		Mode = "ClassEquals";
		Target = "LogService";
	})
	sandbox:AddRule({
		Rule = "Block";
		Mode = "ClassEquals";
		Target = "DataStoreService";
	})
	sandbox:AddRule({
		Rule = "Block";
		Mode = "ClassEquals";
		Target = "MessagingService";
	})
	sandbox:AddRule({
		Rule = "Block";
		Mode = "ClassEquals";
		Target = "InsertService";
	})

	sandbox:SetRequireMode("roblox")

	return sandbox
end

return RBXUnlimited