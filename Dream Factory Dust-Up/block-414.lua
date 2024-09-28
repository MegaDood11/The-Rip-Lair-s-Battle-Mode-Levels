local blockmanager = require("blockmanager")
local escalator = require("blocks/ai/escalator")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
	frames = 4,
	framespeed = 2,
	speed = 2,
	direction = -1
})

escalator.register(blockID)

return block