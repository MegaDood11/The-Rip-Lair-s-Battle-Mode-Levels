local blockmanager = require("blockmanager")
local cp = require("clearpipe_opaque")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	noshadows = true,
	width = 32,
	height = 32,
	small = true,
})

-- Up, down, left, right
cp.registerPipe(blockID, "GATE", "VERT", {true,  false, false, false})

return block