--Editor GFX is based on a GFX by Valentine

local blockManager = require("blockManager")
local missileArea = {}
local blockID = BLOCK_ID
local missileAI = require("AI/missileBill")

local settings = {
	id = blockID,
	sizable = true,
	passthrough = true,

	missileID = blockID,
	spawnGap = 384,
	spawnInterval = 30,
}

blockManager.setBlockSettings(settings)
missileAI.registerBlock(blockID)

return missileArea