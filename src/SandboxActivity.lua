local H6x = require(script.Parent:WaitForChild("H6x"))
local CONST = require(script.Parent:WaitForChild("Constants"))

return (function(SandboxActivity)
	local class = (function(SandboxActivity)
		local function deepClone(item, clones)
			clones = clones or {}
			if CONST.PRIMITIVES[type(item)] then
				return item
			end
			if clones[item] then
				return clones[item]
			end

			if type(item) == "table" then
				local clone = table.create(#item)
				clones[item] = clone
				for key, value in pairs(item) do
					clone[key] = deepClone(value, clones)
				end
			end
			return item
		end

		SandboxActivity.Call = (function(Call)
			local class = (function(Call)
				function Call:Track(func, args, results)
					local activity = self.Activity
					local Name = activity.Name

					local nargs, varArg, name, source = debug.info(func, "ans")

					-- Track the called function's name
					-- Name:Track(func, name)
					Name:Track(func, Name:Get(func))

					-- string.format("from %s %s(%d%s)", source or "UNKNOWN", name, nargs, varArg and ", ..." or "")

					-- Create tables for argument/result names
					local argNames = table.create(args.n)
					local resultNames = table.create(results.n)

					-- Get the names of the arguments and results
					for i=1, args.n do
						argNames[i] = Name:Get(args[i], true)
					end
					for i=1, results.n do
						resultNames[i] = Name:Get(results[i], true)
					end

					-- Add an activity entry
					activity:AddEntry({
						event = "call",
						func = func,
						funcName = Name:Get(func),
						rawName = name,
						args = deepClone(args),
						argNames = argNames,
						results = deepClone(results),
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
						object = deepClone(object),
						index = deepClone(index),
						value = deepClone(value),
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
						index = deepClone(index),
						value = deepClone(value),
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
						object = deepClone(object),
						index = deepClone(index),
						value = deepClone(value),
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
						index = deepClone(index),
						value = deepClone(value),
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
						local realObject = sandbox:GetClean(object)
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
						local realObject = sandbox:GetClean(object)
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
					elseif typeName == "function" then
						local nargs, varArg, name, source = debug.info(object, "ans")
						if name == "" then
							name = "<anonymous>"
						end
						return string.format("<function from %s %s(%d%s)>", source or "UNKNOWN", name, nargs, varArg and ", ..." or "")
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

			local stack = {}
			local stackEntries = {}
			local report = {}

			local sandbox = self.Sandbox
			local function findSafe(tab, value)
				local realValue = sandbox:GetClean(value)
				for index, otherValue in ipairs(tab) do
					local realOtherValue = sandbox:GetClean(otherValue)
					if rawequal(realValue, realOtherValue) then
						return index
					end
				end
			end
			local function getIndex(stackIndex)
				return string.format("<%d>", #stack - (stackIndex - 1))
			end
			local function findStackIndexName(value)
				local stackIndex = findSafe(stack, value)
				return stackIndex and getIndex(stackIndex)
			end

			local function tableToString(tab, getName, defaultName, indent, circular)
				circular = circular or {}
				if circular[tab] then
					return "[Circular]"
				end
				indent = indent or ""
				local nextIndent = string.format("%s%s", indent, "\t")

				local result = {}

				if not next(tab) then
					return string.format("%s%s", indent, defaultName or tostring(tab))
					-- return string.format("%s{}", indent)
				end

				circular[tab] = true
				for index, value in pairs(tab) do
					local indexType = typeof(index)
					local valueType = typeof(value)
					local indexName = circular[index] and self.Name:Get(index, true) or getName(index, self.Name:Get(index, true))
					local valueName = circular[value] and self.Name:Get(value, true) or getName(value, self.Name:Get(value, true))
					indexName = indexType == "table" and tableToString(index, getName, indexName, nextIndent, circular) or indexName
					valueName = valueType == "table" and tableToString(value, getName, valueName, valueType, circular) or valueName

					if indexType == "string" and not string.match(index, "%W") then
						table.insert(result, string.format("%s%s = %s", indent, index, valueName))
					else
						table.insert(result, string.format("%s[%s] = %s", indent, indexName, valueName))
					end
				end
				circular[tab] = nil

				return string.format("%s{\n%s%s\n%s} :: %s",
					indent, nextIndent, table.concat(result, string.format(",\n%s", nextIndent)), indent,
					defaultName or self.Name:Get(tab, true)
				)
			end

			if not format or format == "data" then
				-- Return the raw activity data (Can be manipulated externally)
				return history
			elseif format == "h6x" then
				-- In a format like this:
					--[[
						get game
						get <Previous>.GetService
						call <Previous>(<Previous-1>, "RunService") :: game:GetService("RunService")
						get <Instance RunService "Run Service">.Heartbeat
						get <Previous>.Connect
						call <Previous>(<Previous-1>, <function 0xffffffff>) :: <Instance RunService "Run Service">.Heartbeat:Connect(<function 0xffffffff>)
					--]]

				local function getName(value, default)
					if type(value) == "table" then
						return tableToString(value, getName, default)
					else
						local stackIndexName = findStackIndexName(value)
						if stackIndexName then
							return stackIndexName
						end
					end
					return default
				end
				local asFormat = " as <%d>"

				for _, entry in ipairs(history) do
					local event = entry.event
					local object = entry.object
					local index = entry.index
					local value = entry.value
					local objectName = entry.objectName
					local indexName = entry.indexName
					local valueName = entry.valueName

					local func = entry.func
					local funcName = entry.funcName

					if event == "getGlobal" then
						local isNotPrimitive = not CONST.PRIMITIVES[type(value)]
						table.insert(report, string.format("getGlobal %s%s", indexName, isNotPrimitive and string.format(asFormat, #stack + 1) or ""))
						if isNotPrimitive then
							table.insert(stack, 1, value)
							table.insert(stackEntries, 1, entry)
						end
					elseif event == "setGlobal" then
						indexName = getName(index, indexName)
						valueName = getName(value, valueName)
						table.insert(report, string.format("setGlobal %s = %s", indexName, valueName))
					elseif event == "get" then
						objectName = getName(object, objectName)
						indexName = getName(index, indexName)
						local isNotPrimitive = not CONST.PRIMITIVES[type(value)]
						table.insert(report, string.format("get %s.%s%s", objectName, indexName, isNotPrimitive and string.format(asFormat, #stack + 1) or ""))
						if isNotPrimitive then
							table.insert(stack, 1, value)
							table.insert(stackEntries, 1, entry)
						end
					elseif event == "set" then
						objectName = getName(object, objectName)
						indexName = getName(index, indexName)
						valueName = getName(value, valueName)
						table.insert(report, string.format("set %s.%s = %s", objectName, indexName, valueName))
					elseif event == "call" then
						local methodEntry--[[ = {
							event = "get",
							object = nil,
							index = objectName,
							value = object,
							objectName = "???",
							indexName = objectName,
							valueName = "???"
						}]]
						local stackIndex = findSafe(stack, func)
						if stackIndex then
							methodEntry = stackEntries[stackIndex]
							funcName = getIndex(stackIndex)
						end
						-- funcName = findStackIndexName(func) or funcName
						local argNames = entry.argNames
						local args = entry.args
						local resultNames = entry.resultNames
						local results = entry.results

						for i=1, args.n do
							local arg = args[i]
							argNames[i] = getName(arg, argNames[i])
						end
						local stackIncr = 0
						for i=1, results.n do
							local result = results[i]
							resultNames[i] = getName(result, resultNames[i])
							local isNotPrimitive = not CONST.PRIMITIVES[type(result)]
							if isNotPrimitive then
								stackIncr += 1
							end
							resultNames[i] = string.format("%s%s", resultNames[i], isNotPrimitive and string.format(asFormat, #stack + stackIncr) or "")
						end

						if methodEntry and methodEntry.event == "get" then
							local objectName = methodEntry.objectName
							objectName = getName(methodEntry.object, objectName)
							local indexName = methodEntry.indexName
							indexName = getName(methodEntry.index, indexName)

							local realArg1 = sandbox:GetClean(args[1])
							local realObj = sandbox:GetClean(methodEntry.object)

							if realArg1 == realObj then
								-- Method call
								table.remove(argNames, 1)
								table.insert(report, string.format("call %s:%s(%s)\n -> %s", objectName, indexName, table.concat(argNames, ", "), table.concat(resultNames, ", ")))
							else
								-- Dot call
								table.insert(report, string.format("call %s.%s(%s)\n -> %s", objectName, indexName, table.concat(argNames, ", "), table.concat(resultNames, ", ")))
							end
						-- elseif methodEntry and methodEntry.event == "call" then

						else
							-- Use the raw call string
							table.insert(report, string.format("call %s(%s)\n -> %s", funcName, table.concat(argNames, ", "), table.concat(resultNames, ", ")))
						end
						for _, result in ipairs(results) do
							if not CONST.PRIMITIVES[type(result)] then
								table.insert(stack, 1, result)
								table.insert(stackEntries, 1, entry)
							end
						end
					end
				end
			elseif format == "bytecode" then
				-- TODO: Generate vanilla lua bytecode
			elseif format == "lua" then
				-- TODO: Generate lua code (Not original source, just a readable log which can be executed to "replay" events)
			end
			return table.concat(report, "\n")
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