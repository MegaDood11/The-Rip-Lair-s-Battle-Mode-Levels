local blockmanager = require("blockmanager")
local cp = require("clearpipe_opaque")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	noshadows = true,
	width = 32,
	height = 64
})

-- Up, down, left, right
cp.registerPipe(blockID, "STRAIGHT", "HORZ", {false, false, true,  true})

return block