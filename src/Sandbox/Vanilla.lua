local Sandbox = require(script.Parent:WaitForChild("Sandbox"))

local Vanilla = {}

--[=[
	Creates a sandbox configured for emulating vanilla lua scripts. (WIP)
]=]
function Vanilla.new(options)
	local function copy(tab)
		local tabCopy = {}
		for index, value in pairs(tab) do
			tabCopy[index] = value
		end
		if table.isfrozen(tab) then
			table.freeze(tabCopy)
		end
		return tabCopy
	end

	local function getModule(env, name)

	end

	local function setModule(env, name, module)

	end

	local sandbox

	local ipackage = {
		-- TODO: Actual fake paths
		cpath = "lua5.dll",
		path = "lua5.exe",
		-- TODO: Implement loaders and preload?
		loaders = {},
		preload = {},
		loadlib = function(libname, funcname)
			error("no library", 2) -- TODO: Proper error message
		end,
		seeall = function(module)
			-- TODO: implement?
		end,
		-- Gets overwritten
		loaded = {}
	}

	local function iloadfile(filename)
		-- TODO: File system
		local code = ""
		return sandbox:Poison(loadstring(code))
	end

	options = options or {}
	options.env = {
		assert = assert,
		collectgarbage = collectgarbage,
		error = error,
		getfenv = getfenv,
		getmetatable = getmetatable,
		ipairs = ipairs,
		loadstring = loadstring,
		newproxy = newproxy,
		next = next,
		pairs = pairs,
		pcall = pcall,
		print = print,
		rawequal = rawequal,
		rawget = rawget,
		rawset = rawset,
		select = select,
		setfenv = setfenv,
		setmetatable = setmetatable,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
		xpcall = xpcall,
		_G = {},
		_VERSION = _VERSION,

		table = copy(table),
		string = copy(string),
		math = copy(math),
		coroutine = copy(coroutine),
		os = copy(os),

		require = require,

		-- TODO: Compatability
		debug = copy(debug),
		io = {}, -- TODO: File system
		dofile = function(...) -- TODO: File system
			local func = iloadfile(...)
			return func()
		end,
		load = function(func, chunkname)
			-- TODO: Improve
			local concat = {}

			local segment = true
			while segment and segment ~= "" do
				if segment ~= true then
					table.insert(concat, segment)
				end

				segment = func()
				assert(not segment or type(segment) == "string", "function must return a string") -- TODO: Get proper error message
			end

			local code = table.concat(concat)
			return sandbox:Poison(loadstring(code))
		end,
		loadfile = iloadfile, -- TODO: File system
		package = ipackage,
		module = function(name, ...)
			-- TODO: Proper returns, handle arguments?

			local module = ipackage.loaded[name]
			if module then
				return module
			end

			module = getModule(getfenv(0), name)
			if module then
				return module
			end

			local segments = name:split(".")
			table.remove(segments, #segments)
			local _PACKAGE = table.concat(segments)

			local t = {
				_NAME = name,
				_PACKAGE = _PACKAGE
			}
			t._M = t

			ipackage.loaded[name] = t
			setModule(getfenv(0), name, t)

			setfenv(2, t)

			return t
		end
	}

	sandbox = Sandbox.new(options)

	-- TODO: Compatability
	sandbox:DenyInstances()
	sandbox:SetRequireMode("vanilla")

	ipackage.loaded = sandbox.Modules

	sandbox:AddModule("table", options.env.table)
	sandbox:AddModule("string", options.env.string)
	sandbox:AddModule("math", options.env.math)
	sandbox:AddModule("coroutine", options.env.coroutine)
	sandbox:AddModule("os", options.env.os)
	sandbox:AddModule("io", options.env.io)
	sandbox:AddModule("debug", options.env.debug)

	return sandbox
end

return Vanilla