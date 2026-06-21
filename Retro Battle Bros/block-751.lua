local blockManager = require("blockManager")
local powblockAI = require("battlepowblock")

local powBlock = {}
local blockID = BLOCK_ID

local powBlockSettings = {
	id = blockID,
	frames = 1,
	framespeed = 8,
	heightchange = 8
}

blockManager.setBlockSettings(powBlockSettings)

powblockAI.register(blockID, 3)

return powBlock