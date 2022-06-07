local H6x = require(script.Parent:WaitForChild("H6x"))
local CONST = require(script.Parent:WaitForChild("Constants"))
local Util = require(script.Parent:WaitForChild("Util"))
local Logger = require(script.Parent:WaitForChild("Logger"))

return (function(Sandbox)
	local DO_NOT_IMPORT_OR_EXPORT = newproxy()
	local BLACKLIST_EXCEPTION = newproxy()

	local class = (function(Sandbox)
		function Sandbox:LoadFunction(func)
			return self:Export(self.BaseEnvironment:Apply(func))
		end

		function Sandbox:LoadString(str)
			local func, errMessage = loadstring(str)

			assert(func, errMessage)
			return self:LoadFunction(func)
		end

		-- Restricts a reference-based value from access (Primitives are ignored by this)
		-- Optionally accepts an error message to display (By default displays an "Error occured, no output from Lua." message)
		-- This is different than blacklisting because blacklisting does not create an error
		-- Additionally can optionally terminate the entire sandbox
		function Sandbox:Restrict(value, errMsg, terminate)
			local refBasedTypes = {
				["table"] = true,
				["userdata"] = true,
				["function"] = true,
				["thread"] = true
			}

			local primitive = type(value)
			if not refBasedTypes[primitive] then
				return
			end

			local restrictedValues = self.RestrictedValues
			restrictedValues[value] = {
				Message = errMsg,
				Terminate = terminate
			}
		end

		-- Recursively marks all values under a table as unsafe
		function Sandbox:RestrictTree(object, ...)
			local markQueue = {object}
			local marked = setmetatable({}, CONST.WEAK_METATABLES.Keys)
			while markQueue[1] do
				-- Pop off first table in the queue
				local value = table.remove(markQueue, 1)

				if not marked[value] then
					marked[value] = true

					self:Restrict(value, ...)

					if type(value) == "table" then
						for _, value in pairs(value) do
							table.insert(markQueue, value)
						end
					end
				end
			end
		end

		function Sandbox:EnableActivityTracking()
			error("Activity tracking is not implemented yet", 2)
		end

		function Sandbox:GenerateActivityReport(format)
			return self.SandboxActivity:GenerateReport(format)
		end

		function Sandbox:ActivityEvent(eventType, ...)
			local activity = self.SandboxActivity
			local event = activity[eventType]

			event:Track(...)
		end

		function Sandbox:ExecuteFunction(func, ...)
			return self.BaseRunner:ExecuteFunction(func)
		end

		function Sandbox:ExecuteString(str, ...)
			return self.BaseRunner:ExecuteString(str, ...)
		end

		function Sandbox:Import(object)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real

			local realObject = real[object]
			if realObject ~= nil then
				object = realObject
			end

			local imported = self.imported

			local import = imported[object]
			if import == DO_NOT_IMPORT_OR_EXPORT then
				return object
			end

			if not import then
				if type(object) == "function" then
					local fenv = getfenv(object)
					if fenv == self.env then
						imported[object] = object
						return object
					end

					local table = table
					local pairs = pairs
					local rawequal = rawequal
					function import(...)
						self:CheckTermination()

						local args = table.pack(...)
						for i, arg in pairs(args) do
							if i == "n" then
								continue
							end

							if not rawequal(arg, nil) then
								local realValue = real[arg]
								if realValue ~= nil then
									-- Export the real values if they can be
									args[i] = self:Export(realValue) or realValue
								end
							end
						end

						local results = table.pack(object(Util.unpack(args)))
						for i, result in pairs(results) do
							if i == "n" then
								continue
							end

							if not rawequal(result, nil) then
								-- Import results if they can be
								result = self:Import(result) or result
								-- Then poison the result
								results[i] = self:Poison(result)
							end
						end

						return Util.unpack(results)
					end

					local poisoned = self:Poison(self.BaseEnvironment:Apply(import))

					local realObject = realObject == nil and object or realObject

					real[import] = realObject
					if poisoned then
						real[poisoned] = realObject
						imported[import] = import
						imported[object] = import
						imported[realObject] = import
						imported[poisoned] = import
					end

					return poisoned
				elseif type(object) == "table" or type(object) == "userdata" then
					local import = object
					local poisoned = self:Poison(import)

					local realObject = realObject == nil and object or realObject

					real[import] = realObject
					if poisoned then
						real[poisoned] = realObject
						imported[import] = import
						imported[object] = import
						imported[realObject] = import
						imported[poisoned] = import
					end

					return poisoned
				end
			end

			return self:Poison(import)
		end

		function Sandbox:Export(object)
			local exported = self.exported
			local poisonMap = self.poisonMap
			local real = poisonMap.Real

			local realObject = real[object]
			if realObject ~= nil then
				object = realObject
			end

			local export = exported[object]
			if export == DO_NOT_IMPORT_OR_EXPORT then
				return object
			end

			if not export then
				if type(object) == "function" then
					local fenv = getfenv(object)
					if fenv == self.env then
						exported[object] = object
						return object
					end

					local table = table
					local pairs = pairs
					local rawequal = rawequal
					function export(...)
						self:CheckTermination()

						local args = table.pack(...)
						for i, arg in pairs(args) do
							if i == "n" then
								continue
							end

							if not rawequal(arg, nil) then
								-- Import input arguments if they can be
								arg = self:Import(arg) or arg
								-- Then poison the result
								args[i] = self:Poison(arg)
							end
						end

						local results = table.pack(object(Util.unpack(args)))
						for i, result in pairs(results) do
							if i == "n" then
								continue
							end

							if not rawequal(result, nil) then
								local realValue = real[result]
								if realValue ~= nil then
									-- Export the real values if they can be
									results[i] = self:Export(realValue) or realValue
								end
							end
						end

						return Util.unpack(results)
					end
					self.BaseEnvironment:Apply(export)

					local realObject = realObject ~= nil and realObject or object

					--real[export] = realObject

					--exported[realObject] = export
					exported[object] = export

					return export
				elseif type(object) == "table" or type(object) == "userdata" then
					-- TODO: Export tables & userdatas
					--exported[object] = object
					--return object
				end
			end

			return export
		end

		-- Poisons values to be tracked
		function Sandbox:Poison(object, errorLevel, restrictionErrorLevel)
			local poisonMap = self.poisonMap

			local poisoned = poisonMap.Poisoned

			object = self:FilterValue(object, errorLevel, restrictionErrorLevel)

			local proxy = poisoned[object]
			if proxy then
				return self:FilterValue(proxy, errorLevel, restrictionErrorLevel)
			end

			-- Type tracking
			do
				local tracked = self.Tracked
				local entry = object--H6x.TrackedValue.new(object) -- TODO: Consider using a special type for tracked values?

				table.insert(tracked, entry)

				local byTypeOf = tracked.ByTypeOf
				local byPrimitive = tracked.ByPrimitive

				local typeName = typeof(object)
				local primitive = type(object)

				table.insert(byTypeOf[typeName], object)
				table.insert(byPrimitive[primitive], object)
			end

			local primitive = type(object)
			if primitive == "table" then
				local proxy = {}

				local real = poisonMap.Real
				real[object] = object
				real[proxy] = object
				poisoned[object] = proxy
				poisoned[proxy] = proxy

				local poisonMetatable = H6x.Reflector.from(object, self.poisonMetatable, self)
				return self:FilterValue(setmetatable(proxy, poisonMetatable), errorLevel, restrictionErrorLevel)
			elseif primitive == "userdata" then
				local proxy = newproxy(true)

				local real = poisonMap.Real
				real[object] = object
				real[proxy] = object
				poisoned[object] = proxy
				poisoned[proxy] = proxy

				local poisonMetatable = H6x.Reflector.from(object, self.poisonMetatable, self)
				local meta = getmetatable(proxy)
				for index, value in pairs(poisonMetatable) do
					meta[index] = value
				end
				return self:FilterValue(proxy, errorLevel, restrictionErrorLevel)
			elseif primitive == "function" then
				local proxy = function(...)
					self:CheckTermination()
					local results = table.pack(object(...))
					self:CheckTermination()

					local args = table.pack(...)
					local logResults = table.move(results, 1, results.n, 1, table.create(results.n))
					logResults.n = results.n
					self:ActivityEvent("Call", object, args, logResults)

					for i, result in pairs(results) do
						if i == "n" then
							continue
						end

						if not rawequal(result, nil) then
							results[i] = self:Poison(result)
						end
					end
					self:CheckTermination()

					return Util.unpack(results)
				end

				local real = poisonMap.Real
				real[object] = object
				real[proxy] = object
				poisoned[object] = proxy
				poisoned[proxy] = proxy

				return self:FilterValue(proxy, errorLevel, restrictionErrorLevel)
			end

			return object
		end

		-- Value redirection
		-- Redirect one value to another directly
		function Sandbox:Redirect(valueA, valueB)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real
			local realValueA = real[valueA]

			local redirections = self.Redirections

			if realValueA ~= nil then
				redirections[realValueA] = {
					Value = valueB
				}
			else
				redirections[valueA] = {
					Value = valueB
				}
			end
		end

		-- Gets the redirected value for the target
		function Sandbox:GetRedirected(value)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real

			local realValue = real[value]
			local redirections = self.Redirections

			return redirections[value] or redirections[realValue]
		end

		-- Redirect with a callback instead of directly (Slower)
		function Sandbox:RedirectHandle(valueA, callback)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real
			local realValueA = real[valueA]

			if realValueA == nil then
				realValueA = valueA
			end

			local redirections = self.Redirections

			if not rawequal(realValueA, valueA) then
				redirections[realValueA] = {
					Callback = callback
				}
			else
				redirections[valueA] = {
					Callback = callback
				}
			end
		end

		-- Removes a redirection
		function Sandbox:RemoveRedirect(valueA)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real
			local realValueA = real[valueA]

			if realValueA == nil then
				realValueA = valueA
			end

			local redirections = self.Redirections

			redirections[realValueA] = nil
			redirections[valueA] = nil
		end

		-- Some additional redirector stuff
		function Sandbox:__pairs(...)
			local iterator, tab, index = pairs(...)

			return self:Import(iterator), tab, index
		end
		function Sandbox:__ipairs(...)
			local iterator, tab, index = ipairs(...)

			return self:Import(iterator), tab, index
		end

		function Sandbox:__redirectScript(newScript)
			self:Redirect(script, newScript)
		end

		function Sandbox:SetScript(newScript)
			-- TODO: Full script emulation
			if self.EmulationEvents then
				for _, event in ipairs(self.EmulationEvents) do
					event:Disconnect()
				end
				self.EmulationEvents = nil
			end

			self.EmulatedScript = newScript
			self:__redirectScript(newScript)

			if newScript and newScript:IsA("BaseScript") then
				local wasDisabled = newScript.Disabled

				if wasDisabled and not self.Terminated then
					self:Terminate("Script was disabled")
				end

				self.EmulationEvents = {
					newScript:GetPropertyChangedSignal("Disabled"):Connect(function()
						local disabled = newScript.Disabled

						if disabled ~= wasDisabled then
							if disabled then
								self:Terminate("Script was disabled")
							else
								self:Unterminate()
							end
						end

						wasDisabled = disabled
					end)
				}
			end
		end

		-- Default redirects
		function Sandbox:RedirectorDefaults()
			if not self.DefaultsRedirected then
				-- Backup compatability

				local iwait = self:Import(function(waitTime)
					local thread = coroutine.running()
					delay(waitTime, function(...)
						if not self.Terminated then
							coroutine.resume(thread, ...)
						end
					end)
					return coroutine.yield()
				end)

				local idelay = self:Import(function(waitTime, callback)
					return delay(waitTime, function(...)
						if not self.Terminated then
							return callback(...)
						end
					end)
				end)

				local iresume = self:Import(function(...)
					if not self.Terminated then
						return coroutine.resume(...)
					end
				end)

				self:Redirect(coroutine.resume, iresume)
				self:Redirect(delay, idelay)
				self:Redirect(wait, iwait)

				self:Redirect(ipairs, self:Import(ipairs))
				self:Redirect(pairs, self:Import(pairs))

				local itype = self:Import(type)

				self:Redirect(type, itype)
				self:Redirect(typeof, self:Import(typeof))

				-- Require functionality
				local requireMode = self.RequireMode
				local modules = self.Modules

				local irequire = self:Import(function(...)
					if requireMode == "disable" then
						return error("Require is disabled.", nil)
					end

					local requireTarget = ...

					if modules[requireTarget] then
						return self:Import(modules[requireTarget])
					end

					if requireMode == "roblox" then
						if type(requireTarget) == "number" then
							if not self.AssetRequiresAllowed then
								return error("Attempted to call require with invalid argument(s).", 2)
							end
						end

						local results = table.pack(pcall(require, ...))

						if not results[1] then
							error(results[2], 2)
						end

						table.remove(results, 1)
						results.n -= 1

						return Util.unpack(results)
					elseif requireMode == "vanilla" then
						if type(requireTarget) ~= "string" then
							return error(string.format("bad argument #1 to 'require' (string expected, got %s)", itype(requireTarget)), 2)
						end

						return error(string.format("module '%s' not found:\n        no file '.\\%s.lua'", requireTarget, requireTarget), 2)
					elseif requireMode == "custom" then
						local requireHook = self.CustomRequire

						if requireHook then
							local results = table.pack(pcall(requireHook, ...))

							if not results[1] then
								error(results[2], 2)
							end

							table.remove(results, 1)
							results.n -= 1

							return Util.unpack(results)
						end
					end
					return nil
				end)

				self:Redirect(require, irequire)

				-- Redirect base environment
				local baseEnv = self.BaseEnvironment
				self:Redirect(baseEnv.subenv, baseEnv.env)

				self.DefaultsRedirected = true
			end
		end

		-- Custom requires
		function Sandbox:SetRequireMode(mode)
			if type(mode) ~= "string" then
				self.CustomRequire = mode
				mode = "custom"
			end

			self.RequireMode = mode
		end

		function Sandbox:RestrictAssetRequires()
			self.AssetRequiresAllowed = nil
		end

		function Sandbox:AllowAssetRequires()
			self.AssetRequiresAllowed = true
		end

		function Sandbox:AddModule(target, module)
			self.Modules[target] = self:Import(module)
		end

		-- Allows Instances to be accessed
		function Sandbox:AllowInstances()
			self.allowsInstances = true
		end

		-- Prevents the usage of Instances (default)
		function Sandbox:DenyInstances()
			self.allowsInstances = false
		end

		-- Default restrictions
		function Sandbox:RestrictionDefaults()
			if not self.DefaultsRestricted then
				-- Restrict H6x with termination
				self:RestrictTree(H6x, nil, true)

				-- Restrict self with termination
				self:Restrict(self, nil, true)

				self.DefaultsRestricted = true
			end
		end

		-- Blacklisting functions
		function Sandbox:Blacklist(value)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real

			value = real[value] or value

			local primitive = type(value)

			if CONST.PRIMITIVES[primitive] then
				return error("Cannot blacklist basic value types.", 2)
			end

			self.blacklist[value] = true
		end

		function Sandbox:Except(value)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real

			value = real[value] or value

			local primitive = type(value)

			if CONST.PRIMITIVES[primitive] then
				return error("Cannot blacklist basic value types.", 2)
			end

			self.blacklist[value] = BLACKLIST_EXCEPTION
		end

		function Sandbox:BlacklistType(typeName)
			assert(type(typeName) == "string", "Sandbox:BlacklistType() typeName must be a string")

			self.blacklist[typeName] = true
		end

		function Sandbox:BlacklistPrimitive(primitive)
			assert(type(primitive) == "string", "Sandbox:BlacklistPrimitive() primitive must be a string")

			self.blacklist[CONST.PRIMITIVES[primitive]] = true
		end

		function Sandbox:BlacklistClassName(className)
			assert(type(className) == "string", "Sandbox:BlacklistClassName() className must be a string")

			self.classBlacklist[className] = true
		end

		function Sandbox:ExceptClassName(className)
			assert(type(className) == "string", "Sandbox:ExceptClassName() className must be a string")

			self.classBlacklist[className] = BLACKLIST_EXCEPTION
		end

		function Sandbox:UnblacklistClassName(className)
			assert(type(className) == "string", "Sandbox:UnblacklistClassName() className must be a string")

			self.classBlacklist[className] = nil
		end

		function Sandbox:BlacklistClass(className)
			assert(type(className) == "string", "Sandbox:BlacklistClass() className must be a string")

			self.classTypeBlacklist[className] = true
		end

		function Sandbox:ExceptClass(className)
			assert(type(className) == "string", "Sandbox:ExceptClass() className must be a string")

			self.classTypeBlacklist[className] = BLACKLIST_EXCEPTION
		end

		function Sandbox:UnblacklistClass(className)
			assert(type(className) == "string", "Sandbox:UnblacklistClass() className must be a string")

			self.classTypeBlacklist[className] = nil
		end

		function Sandbox:BlacklistTree(rootInstance)
			assert(typeof(rootInstance) == "Instance", "Sandbox:BlacklistTree() rootInstance must be an Instance")

			self.rootBlacklist[rootInstance] = true
		end

		function Sandbox:ExceptTree(rootInstance)
			assert(typeof(rootInstance) == "Instance", "Sandbox:ExceptTree() rootInstance must be an Instance")

			self.rootBlacklist[rootInstance] = BLACKLIST_EXCEPTION
		end

		function Sandbox:UnblacklistTree(rootInstance)
			assert(typeof(rootInstance) == "Instance", "Sandbox:UnblacklistTree() rootInstance must be an Instance")

			self.rootBlacklist[rootInstance] = nil
		end

		function Sandbox:Unblacklist(valueOrType)
			local poisonMap = self.poisonMap
			local real = poisonMap.Real

			valueOrType = real[valueOrType] or valueOrType

			self.blacklist[valueOrType] = nil
		end

		function Sandbox:UnblacklistPrimitive(primitive)
			self.blacklist[CONST.PRIMITIVES[primitive]] = nil
		end

		function Sandbox:InBlacklist(value, errorLevel, restrictionErrorLevel)
			if errorLevel then
				errorLevel = errorLevel > 0 and (errorLevel + 1) or errorLevel
			end
			if restrictionErrorLevel then
				restrictionErrorLevel = restrictionErrorLevel > 0 and (restrictionErrorLevel + 1) or restrictionErrorLevel
			end

			local blacklist = self.blacklist
			local poisonMap = self.poisonMap

			local real = poisonMap.Real[value] or value

			-- Handle value restrictions
			if restrictionErrorLevel then
				local restrictedValues = self.RestrictedValues
				local restrictionErr = restrictedValues[real]
				if restrictionErr then
					local message = restrictionErr.Message

					if restrictionErr.Terminate then
						self:Terminate(message or true)
					end

					return error(message, restrictionErrorLevel or 0)
				end
			end

			local primitive = type(real)
			local primId = CONST.PRIMITIVES[primitive]
			if primId then
				local blacklisted = blacklist[primId]
				if blacklisted then
					if blacklisted == BLACKLIST_EXCEPTION then
						return false
					end

					-- Blacklisted primitive
					if errorLevel then
						error("Attempt to access blacklisted primitive", errorLevel)
					end
					return blacklisted
				end
			else
				local blacklisted = blacklist[real] or blacklist[value]
				if blacklisted then
					if blacklisted == BLACKLIST_EXCEPTION then
						return false
					end

					-- Blacklisted value
					if errorLevel then
						error("Attempt to access blacklisted value", errorLevel)
					end
					return blacklisted
				end

				local typeName = typeof(real)

				local blacklisted = blacklist[typeName]
				if blacklisted then
					if blacklisted == BLACKLIST_EXCEPTION then
						return false
					end

					-- Blacklisted type
					if errorLevel then
						error("Attempt to access blacklisted type", errorLevel)
					end
					return blacklisted
				end

				if typeName == "Instance" then
					local classBlacklist = self.classBlacklist
					local blacklisted = classBlacklist[real.ClassName]
					if blacklisted then
						if blacklisted == BLACKLIST_EXCEPTION then
							return false
						end

						-- Blacklisted class
						if errorLevel then
							error("Attempt to access blacklisted ClassName", errorLevel)
						end
						return blacklisted
					end

					local classTypeBlacklist = self.classTypeBlacklist
					local blacklisted
					for className, isBlacklisted in pairs(classTypeBlacklist) do
						if real:IsA(className) then
							if isBlacklisted == BLACKLIST_EXCEPTION then
								return false
							end

							if isBlacklisted then
								blacklisted = isBlacklisted
							end
						end
					end

					if blacklisted then
						-- Blacklisted class
						if errorLevel then
							error("Attempt to access blacklisted class type", errorLevel)
						end
						return blacklisted
					end

					local rootBlacklist = self.rootBlacklist
					local blacklisted
					for rootInstance, isBlacklisted in pairs(rootBlacklist) do
						if real == rootInstance or real:IsDescendantOf(rootInstance) then
							if isBlacklisted == BLACKLIST_EXCEPTION then
								return false
							end

							if isBlacklisted then
								blacklisted = isBlacklisted
							end
						end
					end

					if blacklisted then
						-- Blacklisted class
						if errorLevel then
							error("Attempt to access blacklisted instance heirarchy", errorLevel)
						end
						return blacklisted
					end

					if not self.allowsInstances then
						if errorLevel then
							error("Attempt to access blacklisted instance", errorLevel)
						end
						return true
					end
				end
			end

			return false
		end

		-- Filters an input value based on the blacklist
		function Sandbox:FilterValue(value, errorLevel, restrictionErrorLevel)
			if errorLevel then
				errorLevel = errorLevel > 0 and (errorLevel + 1) or errorLevel
			end
			if restrictionErrorLevel then
				restrictionErrorLevel = restrictionErrorLevel > 0 and (restrictionErrorLevel + 1) or restrictionErrorLevel
			end

			if not self:InBlacklist(value, errorLevel, restrictionErrorLevel) then
				--local redirections = self.Redirections

				--local redirect = redirections[value]
				local redirect = self:GetRedirected(value)
				if redirect then
					local callback = redirect.Callback
					if callback then
						local safeMode = redirect.SafeMode

						-- Only do the callback if its not the value being filtered. If the callback is being filtered we return it raw.
						if callback ~= value then
							-- Sandbox safe mode (Don't pass the sandbox, basically, we assume the callback is user code)
							if safeMode then
								-- Poison the callback so it will return poisoned values, then export it so it only receives poisoned values 
								callback = self:Export(self:Poison(callback))

								return self:Poison(callback(value))
							end

							return self:Poison(callback(self, value))
						else
							return callback
						end
					end

					return redirect.Value
				end

				return value
			end
		end

		-- Terminates the sandbox and stops code from running
		function Sandbox:Terminate(terminationMessage)
			self.Terminated = terminationMessage or true--"Script terminated"

			-- Disable the emulated script
			local emulatedScript = self.EmulatedScript
			if emulatedScript and emulatedScript:IsA("BaseScript") then
				emulatedScript.Disabled = true
			end

			-- Disable the runner script if it can be
			local runner = self.BaseRunner
			local scriptObject = runner.ScriptObject

			if scriptObject:IsA("BaseScript") then
				scriptObject.Disabled = true
			end

			-- Get tracked values so we can clean up
			local tracked = self.Tracked
			local byTypeOf = tracked.ByTypeOf
			local byType = tracked.ByPrimitive

			-- Get all of the event connections tracked by the sandbox
			local connections = byTypeOf.RBXScriptConnection

			-- Get all of the threads tracked by the sandbox
			local threads = byType.thread

			-- Disconnect all event connections
			for index, connection in ipairs(connections) do
				connection:Disconnect() -- Disconnect event connection
				connections[index] = nil -- Clear from table
			end

			--local loopStart = os.clock()
			--local suspendWarning = false -- Whether or not the suspension warning has been shown
			local function killThread(thread)
				local status = coroutine.status(thread)
				if status ~= "dead" then
					if status == "normal" then -- An ancestor thread is the terminating thread
						return true -- Flag to terminate the caller
					elseif status == "suspended" then
						-- Close the thread
						coroutine.close(thread)

						---- Continuously resume the thread to kill it
						--while status == "suspended" or status == "normal" do
						--	-- If time since the loop start is more than 1 second break out of the loop and output a warning
						--	if os.clock() - loopStart >= 1 then
						--		if not suspendWarning then
						--			warn(LOG_PREFIX, "One or more threads are preventing themselves from quitting and over a second of run time has been used attempting to end them. Continuing without ending them. (Logic code may continue to run after this, but it will immediately exit if external code is utilized)")
						--		end
						--		break
						--	end

						--	local success, errMsg = coroutine.resume(thread)
						--	if not success then -- Thread errored, so, it must be dead
						--		break
						--	end

						--	status = coroutine.status(thread)
						--end

						---- Take whatever approach makes sense now that the thread is in a different state
						--return killThread(thread)
					elseif status == "running" then -- Currently this case should never happen
						-- Yield the running thread and close it
						coroutine.yield()
						task.defer(coroutine.close, thread)
					else
						-- Error on unknown thread status
						--error(table.concat({LOG_PREFIX, "An unknown thread status was encountered:", status}, " "), 2)
						Logger:Notice("An unknown thread status was encountered while terminating:", status)
					end
				end
			end

			-- Kill all threads
			local terminateCaller = false
			for index, thread in ipairs(threads) do
				killThread(thread)
			end

			-- Terminate the caller if flagged
			if terminateCaller then
				-- Silently yield forever (Will GC just fine)
				coroutine.yield()
			end
		end

		function Sandbox:CheckTermination()
			local terminationMessage = self.Terminated
			if terminationMessage then
				if terminationMessage == true then
					-- Silently yield forever

					local yieldAttempts = 0
					while true do
						local success = pcall(coroutine.yield)

						yieldAttempts += 1
						if not success or yieldAttempts >= 100 then
							return error("cannot resume dead coroutine")
						end
					end
				end

				error(terminationMessage, 0)
			end
		end

		function Sandbox:Unterminate()
			self.Terminated = nil

			-- Enable the emulated script
			local emulatedScript = self.EmulatedScript
			if emulatedScript and emulatedScript:IsA("BaseScript") then
				emulatedScript.Disabled = false
			end

			-- Enable the runner script if it can be enabled
			local runner = self.BaseRunner
			local scriptObject = runner.ScriptObject

			if scriptObject:IsA("BaseScript") then
				scriptObject.Disabled = false
			end
		end

		return Sandbox
	end)({})
	class.__index = class

	local function __index(object, real, index)
		if real then
			return real[index]
		end
		return rawget(object, index)
	end

	Sandbox.Empty = (function(Empty)
		function Empty.new(options)
			local function copy(tab)
				local tabCopy = {}
				for index, value in pairs(tab) do
					tabCopy[index] = value
				end
				return tabCopy
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

				table = copy(table),
				string = copy(string),
				math = copy(math),
				os = copy(os),
			}

			local sandbox = Sandbox.new(options)

			sandbox:DenyInstances()
			sandbox:SetRequireMode("vanilla")

			return sandbox
		end
	end)({})
	Sandbox.Limited = (function(Limited)
		function Limited.new(options)
			local sandbox = Sandbox.new(options)

			sandbox:DenyInstances()
			sandbox:Blacklist(workspace)
			sandbox:Blacklist(game)
			sandbox:ExceptClass("Folder")
			sandbox:ExceptClass("PVInstance")
			sandbox:ExceptClass("Constraint")
			sandbox:ExceptClass("WeldConstraint")
			sandbox:ExceptClass("JointInstance")
			sandbox:ExceptClass("Attachment")
			sandbox:ExceptClass("FaceInstance")

			sandbox:ExceptClass("BodyMover")

			sandbox:ExceptClass("Smoke")
			sandbox:ExceptClass("Fire")
			sandbox:ExceptClass("Sparkles")
			sandbox:ExceptClass("ParticleEmitter")
			sandbox:ExceptClass("Light")
			sandbox:ExceptClass("Explosion")

			sandbox:ExceptClass("Trail")
			sandbox:ExceptClass("Beam")

			sandbox:ExceptClass("ClickDetector")
			sandbox:ExceptClass("ObjectValue")
			sandbox:ExceptClass("StringValue")
			sandbox:ExceptClass("IntValue")
			sandbox:ExceptClass("NumberValue")
			sandbox:ExceptClass("RayValue")
			sandbox:ExceptClass("Vector3Value")
			sandbox:ExceptClass("Color3Value")
			sandbox:ExceptClass("BrickColorValue")
			sandbox:ExceptClass("BoolValue")
			sandbox:ExceptClass("CFrameValue")

			sandbox:ExceptClass("Sky")
			sandbox:ExceptClass("PostEffect")

			--sandbox:ExceptClass("PlayerGui")
			sandbox:ExceptClass("UIBase")
			sandbox:ExceptClass("GuiBase")

			sandbox:ExceptClass("Message")
			sandbox:ExceptClass("Dialog")
			sandbox:ExceptClass("Camera")

			sandbox:ExceptClass("Accoutrement")

			--sandbox:ExceptClass("RemoteFunction")
			--sandbox:ExceptClass("RemoteEvent")
			--sandbox:ExceptClass("BindableFunction")
			--sandbox:ExceptClass("BindableEvent")

			sandbox:ExceptClass("CharacterAppearance")
			--sandbox:ExceptClass("Humanoid")

			--sandbox:ExceptClass("RunService")

			--sandbox:ExceptClass("UserInputService")
			sandbox:ExceptClass("InputObject")
			sandbox:ExceptClass("Mouse")

			sandbox:SetRequireMode("vanilla")

			return sandbox
		end
	end)({})
	Sandbox.User = (function(User)
		function User.new(options)
			local sandbox = Sandbox.new(options)

			sandbox:BlacklistType("Instance")
			sandbox:SetRequireMode("vanilla")

			return sandbox
		end
	end)({})
	Sandbox.Roblox = (function(Roblox)
		function Roblox.new(options)
			local sandbox = Sandbox.new(options)

			--sandbox:AllowAssetRequires()

			sandbox:BlacklistClass("TeleportService")
			sandbox:BlacklistClass("MarketplaceService")
			sandbox:BlacklistClass("LogService")
			sandbox:BlacklistClass("DataStoreService")
			sandbox:BlacklistClass("MessagingService")
			sandbox:BlacklistClass("InsertService")

			sandbox:SetRequireMode("roblox")
			
			sandbox:BlacklistTree(script.Parent) -- Prevents the H6x module from being required

			return sandbox
		end
	end)({})
	Sandbox.Vanilla = (function(Vanilla)
		function Vanilla.new(options)
			local function copy(tab)
				local tabCopy = {}
				for index, value in pairs(tab) do
					tabCopy[index] = value
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
						return
					end

					module = getModule(getfenv(0), name)
					if module then
						return
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

			sandbox:AddModule("")

			return sandbox
		end
	end)({})
	-- TODO
	Sandbox.Plugin = (function(Plugin)
		function Plugin.new(options)
			local sandbox = Sandbox.new(options)

			-- TODO: Compatability
			-- TODO: Define "plugin" (Finish definition API)

			return sandbox
		end
	end)({})

	function Sandbox.new(options)
		local poisonMap = {
			Real = setmetatable({}, CONST.WEAK_METATABLES.Keys),
			Poisoned = setmetatable({}, CONST.WEAK_METATABLES.Keys)
		}
		local blacklist = setmetatable({}, CONST.WEAK_METATABLES.Keys)
		local classBlacklist = setmetatable({}, CONST.WEAK_METATABLES.Keys)
		local classTypeBlacklist = setmetatable({}, CONST.WEAK_METATABLES.Keys)
		local rootBlacklist = setmetatable({}, CONST.WEAK_METATABLES.Keys)

		local imported = {}--setmetatable({}, CONST.WEAK_METATABLES.Keys)
		local exported = {}--setmetatable({}, CONST.WEAK_METATABLES.Keys)
		local Environments = setmetatable({}, CONST.WEAK_METATABLES.Keys)

		-- Basic metatable to automatically fill tables in for any nil value
		local autoFiller = {
			__index = function(self, index)
				local fill = setmetatable({}, CONST.WEAK_METATABLES.Values)
				self[index] = fill
				return fill
			end
		}

		-- Tracker info
		-- Stores values accessible to the sandbox by their types and in the tracked list
		local byTypeOf = setmetatable({}, autoFiller)
		local byPrimitive = setmetatable({}, autoFiller)
		local tracked = setmetatable({
			ByTypeOf = byTypeOf,
			ByPrimitive = byPrimitive
		}, CONST.WEAK_METATABLES.Values)

		-- Redirections
		local redirections = setmetatable({}, CONST.WEAK_METATABLES.Keys)

		-- Restricted values
		local restrictedValues = setmetatable({}, CONST.WEAK_METATABLES.Keys)

		-- Object creation
		do
			local self
			local function doImport(value, index)
				local primitive = type(value)

				--if DEBUG_LOGS then
				--	if POISON_LOGS then
				--		print(LOG_PREFIX, "Poison IMPORT", primitive, index, value)
				--	end
				--end
				Logger:Log("POISON:doImport", Logger.Verbosity.Poison, primitive, index, value)

				if primitive == "function" or primitive == "table" or primitive == "userdata" then
					-- Import value
					return self:Import(value)
				end

				return value
			end
			self = {
				__refs = {byTypeOf, byPrimitive},
				Terminated = false,

				RequireMode = "roblox",
				Modules = {},

				Tracked = tracked,

				Redirections = redirections,
				RestrictedValues = restrictedValues,

				allowsInstances = false,

				imported = imported,
				exported = exported,

				blacklist = blacklist,
				classBlacklist = classBlacklist,
				classTypeBlacklist = classTypeBlacklist,
				rootBlacklist = rootBlacklist,

				poisonMap = poisonMap,
				poisonMetatable = {
					__index = function(object, index)
						self:CheckTermination()

						local real = poisonMap.Real[object] or object

						-- Get & filter value
						local value = __index(object, real, index)

						if type(value) == "function" then
							-- Check if the type can be mutated
							if not CONST.MUTABLE_TYPES[typeof(real)] then
								-- Perform an import on the value
								value = doImport(value, index)
							end
						elseif type(value) == "table" then
							-- Perform an import on the table
							value = doImport(value, index)
						end

						if imported[real] then
							-- Perform an import on the value
							value = doImport(value, index)
						end

						--if DEBUG_LOGS then
						--	if VERBOSE_LOGS then
						--		print(LOG_PREFIX, "Poison __index", index, value)
						--	end
						--end
						Logger:Log("POISON:__index", Logger.Verbosity.Poison, index, value)

						-- If the object is not the global environment, log it
						if not rawequal(object, self.BaseEnvironment.env) then
							self:ActivityEvent("Get", object, index, value)
						end

						-- Poison value
						return self:Poison(value, nil, 0)
					end,
					__newindex = function(object, index, value)
						self:CheckTermination()

						local real = poisonMap.Real[object] or object

						if not rawequal(value, nil) then
							if not imported[value] then
								imported[value] = DO_NOT_IMPORT_OR_EXPORT
							end
							if not exported[value] then
								exported[value] = DO_NOT_IMPORT_OR_EXPORT
							end
						end

						--if imported[real] then
						--	if not imported[value] then
						--		imported[value] = DO_NOT_IMPORT_OR_EXPORT
						--	end
						--elseif exported[real] then
						--	if not exported[value] then
						--		exported[value] = DO_NOT_IMPORT_OR_EXPORT
						--	end
						--end

						--if DEBUG_LOGS then
						--	if VERBOSE_LOGS then
						--		print(LOG_PREFIX, "Poison __newindex", real, index, value)
						--	end
						--end
						Logger:Log("POISON:__newindex", Logger.Verbosity.Poison, real, index, value)

						if not rawequal(object, self.BaseEnvironment.env) then
							self:ActivityEvent("Set", object, index, value)
						end

						if real then
							real[index] = value
							return
						end

						if type(object) == "table" then
							rawset(object, index, value)
						end
					end,
					--__metatable = "PRIVATE METATABLE"
				},
				Environments = Environments
			}

			setmetatable(self, class)

			if not options then
				options = {}
			end

			local baseEnv = options.env or getfenv()

			self.SandboxActivity = H6x.SandboxActivity.new(self)
			self.BaseEnvironment = H6x.Environment.new(self, baseEnv)
			self.BaseRunner = H6x.Runner.new(self)

			-- Restrict H6x module
			if not options.NoRestrictionDefaults then
				self:RestrictionDefaults()
			end
			-- Default redirects
			if not options.NoRedirectorDefaults then
				self:RedirectorDefaults()
			end

			-- Import the environment
			self:Import(self.BaseEnvironment.env)

			return self
		end
	end

	return Sandbox
end)({})