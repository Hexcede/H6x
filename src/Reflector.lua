local H6x = require(script.Parent:WaitForChild("H6x"))
local Logger = require(script.Parent:WaitForChild("Logger"))

local Reflector = {}

--function Reflector:__index(real, index)
--	return real[index]
--end
--function Reflector:__newindex(real, index, value)
--	real[index] = value
--end
--function Reflector:__call(real, ...)
--	return real(...)
--end
function Reflector:__concat(real, value)
	return real .. value
end
function Reflector:__unm(real)
	return -real
end
function Reflector:__add(real, value)
	return real + value
end
function Reflector:__sub(real, value)
	return real - value
end
function Reflector:__mul(real, value)
	return real * value
end
function Reflector:__div(real, value)
	return real / value
end
function Reflector:__mod(real, value)
	return real % value
end
function Reflector:__pow(real, value)
	return real ^ value
end
function Reflector:__tostring(real)
	return tostring(real)
end
function Reflector:__eq(real, value)
	-- Note: This case is different than other metamethods.
	-- Here we want the reflected object to be equal if compared with itself
	return rawequal(self, value) or real == value
end
function Reflector:__lt(real, value)
	return real < value
end
function Reflector:__le(real, value)
	return real <= value
end
-- TODO: Re-implement properly (Breaks H6x with new __len changes)
-- function Reflector:__len(real)
-- 	return #real
-- end

function Reflector.new(real, sandbox)
	local self = {}
	for index, func in pairs(Reflector) do
		if not string.sub(index, 1, 2) == "__" then
			continue
		end
		if index == "__tostring" then
			if type(real) == "table" then
				continue
			end
		end

		if sandbox then
			if sandbox.BaseEnvironment then
				self[index] = sandbox:Import(function(object, ...)
					return func(object, real, ...)
				end)
			else
				self[index] = function(...)
					if sandbox.BaseEnvironment then
						self[index] = sandbox:Import(function(object, ...)
							return func(object, real, ...)
						end)
						return self[index](...)
					else
						--warn(LOG_PREFIX, "Failed to retrieve sandbox environment for reflector imports")
						Logger:Warn("Failed to retrieve sandbox environment for reflector imports.")
					end
				end
			end
		else
			self[index] = function(object, ...)
				return func(object, real, ...)
			end
		end
	end
	self.__metatable = getmetatable(real)
	self.__index = real
	self.__newindex = real
	self.__call = real
	return self
end

function Reflector.from(real, meta, sandbox)
	local reflector = Reflector.new(real, sandbox)
	for index, value in pairs(meta) do
		reflector[index] = value
	end
	return reflector
end

return Reflector