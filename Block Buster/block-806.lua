local blockmanager = require("blockmanager")
local cp = require("clearpipe_opaque")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	noshadows = true,
	width = 64,
	height = 64
})

-- Up, down, left, right
cp.registerPipe(blockID, "ELB", "PLUS", {false, true,  true,  false})

return block