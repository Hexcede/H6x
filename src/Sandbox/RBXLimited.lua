local Sandbox = require(script.Parent:WaitForChild("Sandbox"))

local RBXLimited = {}

--[=[
	Creates a limited Roblox sandbox with only specific classes allowed.
]=]
function RBXLimited.new(options)
	local sandbox = Sandbox.new(options)

	sandbox:DenyInstances()

	local allowedClasses = {
		"Folder";
		"PVInstance";
		"Constraint";
		"WeldConstraint";
		"JointInstance";
		"Attachment";
		"FaceInstance";

		"BodyMover";

		"Smoke";
		"Fire";
		"Sparkles";
		"ParticleEmitter";
		"Light";
		"Explosion";

		"Trail";
		"Beam";

		"ClickDetector";
		"ObjectValue";
		"StringValue";
		"IntValue";
		"NumberValue";
		"RayValue";
		"Vector3Value";
		"Color3Value";
		"BrickColorValue";
		"BoolValue";
		"CFrameValue";

		"Sky";
		"PostEffect";

		-- "PlayerGui";
		"UIBase";
		"GuiBase";

		"Message";
		"Dialog";
		"Camera";

		"Accoutrement";

		-- "RemoteFunction";
		-- "RemoteEvent";
		-- "BindableFunction";
		-- "BindableEvent";

		-- "CharacterAppearance";
		-- "Humanoid";

		-- "RunService";

		-- "UserInputService";
		"InputObject";
		"Mouse";
	}
	for _, className in ipairs(allowedClasses) do
		sandbox:AddRule({
			Rule = "Allow";
			Mode = "IsA";
			Target = className;
		})
	end

	sandbox:AddRule({
		Rule = "Block";
		Mode = "IsDescendantOfInclusive";
		Order = -1;
		Target = game;
	})
	sandbox:AddRule({
		Rule = "Block";
		Mode = "IsDescendantOfInclusive";
		Order = -1;
		Target = workspace;
	})

	sandbox:SetRequireMode("vanilla")

	return sandbox
end

return RBXLimited