local blockManager = require("blockManager")
local AI = require("AI/tackleFireGenerator")
local sampleBlock = {}
local blockID = BLOCK_ID

local sampleBlockSettings = {
	id         = blockID,
	frames     = 3,
	framespeed = 8,

	projectileID = blockID - 3,
	warnTime = 8,
	shootDelay = 8,
}

blockManager.setBlockSettings(sampleBlockSettings)
AI.register(blockID, AI.DIR_RIGHT)

return sampleBlock