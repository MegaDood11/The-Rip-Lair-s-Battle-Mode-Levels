local bigblock = require("biganimblock")

local blockmanager = require("blockmanager")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID
})

bigblock.register(blockID)

return block