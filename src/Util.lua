local Util = {}
function Util.unpack(tab)
	return table.unpack(tab, 1, rawget(tab, "n"))
end
function Util.isCFunction(func)
	local source, line = debug.info(func, "sl")
	return source == "[C]" and line == -1
end
return Util