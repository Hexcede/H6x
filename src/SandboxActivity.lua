local H6x = require(script.Parent:WaitForChild("H6x"))
local CONST = require(script.Parent:WaitForChild("Constants"))

return (function(SandboxActivity)
	local class = (function(SandboxActivity)
		SandboxActivity.Call = (function(Call)
			local class = (function(Call)
				function Call:Track(func, args, results)
					local activity = self.Activity
					local Name = activity.Name

					local nargs, varArg, name, source = debug.info(func, "ans")

					-- Track the called function's name
					Name:Track(func, name)

					-- Create tables for argument/result names
					local argNames = table.create(#args)
					local resultNames = table.create(#results)

					-- Get the names of the arguments and results
					for i=1, args.n or #args do
						argNames[i] = Name:Get(args[i], true)
					end
					for i=1, results.n or #results do
						resultNames[i] = Name:Get(results[i], true)
					end

					-- Add an activity entry
					activity:AddEntry({
						event = "call",
						func = func,
						funcName = Name:Get(func),
						rawName = name,
						argNames = argNames,
						resultNames = resultNames
					})
				end

				return Call
			end)({})
			class.__index = class

			function Call.new(activity)
				local self = {
					Activity = activity
				}

				return setmetatable(self, class)
			end

			return Call
		end)({})

		SandboxActivity.Get = (function(Get)
			local class = (function(Get)
				function Get:Track(object, index, value)
					local activity = self.Activity
					local Name = activity.Name

					-- Track the returned value's name
					Name:Track(value, Name:Get(index))

					-- Add an activity entry
					activity:AddEntry({
						event = "get",
						object = object,
						index = index,
						value = value,
						objectName = Name:Get(object),
						indexName = Name:Get(index),
						valueName = Name:Get(value),
					})
				end

				return Get
			end)({})
			class.__index = class

			function Get.new(activity)
				local self = {
					Activity = activity
				}

				return setmetatable(self, class)
			end

			return Get
		end)({})

		SandboxActivity.GetGlobal = (function(GetGlobal)
			local class = (function(GetGlobal)
				function GetGlobal:Track(index, value)
					local activity = self.Activity
					local Name = activity.Name

					-- Track the returned value's name
					Name:Track(value, Name:Get(index))

					-- Add an activity entry
					activity:AddEntry({
						event = "getGlobal",
						index = index,
						value = value,
						indexName = Name:Get(index),
						valueName = Name:Get(value),
					})
				end

				return GetGlobal
			end)({})
			class.__index = class

			function GetGlobal.new(activity)
				local self = {
					Activity = activity
				}

				return setmetatable(self, class)
			end

			return GetGlobal
		end)({})

		SandboxActivity.Set = (function(Set)
			local class = (function(Set)
				function Set:Track(object, index, value)
					local activity = self.Activity
					local Name = activity.Name

					-- Track the set value's name
					Name:Track(value, Name:Get(index))

					-- Add an activity entry
					activity:AddEntry({
						event = "set",
						object = object,
						index = index,
						value = value,
						objectName = Name:Get(object),
						indexName = Name:Get(index),
						valueName = Name:Get(value),
					})
				end

				return Set
			end)({})
			class.__index = class

			function Set.new(activity)
				local self = {
					Activity = activity
				}

				return setmetatable(self, class)
			end

			return Set
		end)({})

		SandboxActivity.SetGlobal = (function(SetGlobal)
			local class = (function(SetGlobal)
				function SetGlobal:Track(index, value)
					local activity = self.Activity
					local Name = activity.Name

					-- Track the set value's name
					Name:Track(value, Name:Get(index))

					-- Add an activity entry
					activity:AddEntry({
						event = "setGlobal",
						index = index,
						value = value,
						indexName = Name:Get(index),
						valueName = Name:Get(value),
					})
				end

				return SetGlobal
			end)({})
			class.__index = class

			function SetGlobal.new(activity)
				local self = {
					Activity = activity
				}

				return setmetatable(self, class)
			end

			return SetGlobal
		end)({})

		SandboxActivity.Name = (function(Name)
			local class = (function(Name)
				function Name:Track(object, name)
					if object == nil then
						return
					end

					local names = self.Names

					local activity = self.Activity
					local sandbox = activity.Sandbox
					if sandbox then
						local poisonMap = sandbox.poisonMap

						local real = poisonMap.Real

						local realObject = real[object]

						if realObject then
							object = realObject
						end
					end

					names[object] = name
				end

				function Name:Get(object, specialMode)
					local activity = self.Activity
					local sandbox = activity.Sandbox
					if sandbox then
						local poisonMap = sandbox.poisonMap

						local real = poisonMap.Real

						local realObject = real[object]

						if realObject then
							object = realObject
						end
					end

					local names = self.Names
					local typeName = typeof(object)

					if typeName == "string" then
						if specialMode then
							return string.format("%q", object)
						end
						return object
					elseif typeName == "number" then
						return tostring(object)
					end

					local nameTable = {"<", typeName, " ", tostring((names[object] or object)), ">"}
					if typeName == "Instance" then
						table.insert(nameTable, 5, string.format(" %q", tostring(object)))
					end
					return table.concat(nameTable)
				end

				return Name
			end)({})
			class.__index = class

			function Name.new(activity)
				local self = {
					Names = setmetatable({}, CONST.WEAK_METATABLES.Keys),
					Activity = activity
				}

				return setmetatable(self, class)
			end

			return Name
		end)({})

		function SandboxActivity:AddEntry(entry)
			local history = self.History

			table.insert(history, entry)
		end

		function SandboxActivity:Reset()
			local history = self.History

			setmetatable(history, CONST.WEAK_METATABLES.Both)

			self.History = {}
		end

		function SandboxActivity:GenerateReport(format)
			local history = self.History

			if not format or format == "data" then
				-- Return the raw activity data (Can be manipulated externally)
				return history
			elseif format == "h6x" then
				-- In a format like this:
					--[[
						get game
						get <Previous>.GetService
						call <Previous>(<Previous-1>, "RunService") @ game:GetService("RunService")
						get <Instance RunService "Run Service">.Heartbeat
						get <Previous>.Connect
						call <Previous>(<Previous-1>, <function 0xffffffff>) @ <Instance RunService "Run Service">.Heartbeat:Connect(<function 0xffffffff>)
					--]]

				-- TODO: Stack tracking & generating simplified

				local report = {}
				for _, entry in ipairs(history) do
					local line = {}

					local event = entry.event
					table.insert(line, event)

					if event == "get" or event == "set" then
						local objectName = entry.objectName
						local indexName = entry.indexName
						local valueName = entry.valueName

						table.insert(line, string.format("%s.%s = %s", objectName, indexName, valueName))
					elseif event == "getGlobal" or event == "setGlobal" then
						local indexName = entry.indexName
						local valueName = entry.valueName

						table.insert(line, string.format("%s = %s", indexName, valueName))
					elseif event == "call" then
						local funcName = entry.funcName
						local argNames = entry.argNames
						local resultNames = entry.resultNames

						table.insert(line, string.format("%s(%s)", funcName, table.concat(argNames, ", ")))

						table.insert(line, "\n\treturn")
						table.insert(line, table.concat(resultNames, ", "))
					end

					table.insert(report, table.concat(line, " "))
				end
				return table.concat(report, "\n")
			elseif format == "bytecode" then
				-- TODO: Generate vanilla lua bytecode
			elseif format == "lua" then
				-- TODO: Generate lua code (Not original source, just a readable log which can be executed to "replay" events)
			end
		end

		return SandboxActivity
	end)({})
	class.__index = class

	function SandboxActivity.new(sandbox)
		local self = {
			Sandbox = sandbox,
			History = {}
		}

		self.Call = class.Call.new(self)
		self.Get = class.Get.new(self)
		self.GetGlobal = class.GetGlobal.new(self)
		self.Set = class.Set.new(self)
		self.SetGlobal = class.SetGlobal.new(self)
		self.Name = class.Name.new(self)

		return setmetatable(self, class)
	end

	return SandboxActivity
end)({})