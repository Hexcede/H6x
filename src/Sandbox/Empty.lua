local Sandbox = require(script.Parent:WaitForChild("Sandbox"))
local Util = require(script.Parent.Parent:WaitForChild("Util"))

local Empty = {}

--[=[
	Creates an (almost) empty sandbox with just some basic lua functions.
]=]
function Empty.new(options)
	local function copyTable(tab)
		local copy = Util.copy(tab)
		if table.isfrozen(tab) then
			table.freeze(copy)
		end
		return copy
	end

	options = options or {}
	options.env = {
		ipairs = ipairs,
		pairs = pairs,
		print = print,
		assert = assert,
		error = error,
		pcall = pcall,
		xpcall = xpcall,
		next = next,
		--rawequal = rawequal,
		--rawget = rawget,
		--rawset = rawset,
		select = select,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,

		table = copyTable(table),
		string = copyTable(string),
		math = copyTable(math),
		os = copyTable(os),
	}

	local sandbox = Sandbox.new(options)
	sandbox:SetRequireMode("vanilla")
	return sandbox
end

return Empty