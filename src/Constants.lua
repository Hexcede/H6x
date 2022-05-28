return {
	WEAK_METATABLES = table.freeze({
		Keys = table.freeze({
			__mode = "k"
		}),
		Values = table.freeze({
			__mode = "v"
		}),
		Both = table.freeze({
			__mode = "kv"
		})
	}),
	PRIMITIVES = {
		["string"] = 1,
		["boolean"] = 2,
		["number"] = 3,
		["nil"] = 4,
		["vector"] = 5
	},
	MUTABLE_TYPES = {
		["userdata"] = true,
		["table"] = true
	}
}