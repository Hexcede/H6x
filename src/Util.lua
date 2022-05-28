local Util = {}
function Util.unpack(tab)
	return table.unpack(tab, 1, rawget(tab, "n"))
end
return Util