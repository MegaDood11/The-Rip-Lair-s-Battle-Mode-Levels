--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

--Create the library table
local sampleBlock = {}
--BLOCK_ID is dynamic based on the name of the library file
local blockID = BLOCK_ID

--Defines Block config for our Block. You can remove superfluous definitions.
local sampleBlockSettings = {
	id = blockID,
	frames = 5,
	framespeed = 8, --# frames between frame change
	bumpable = true, --can be hit from below
}

--Applies blockID settings
blockManager.setBlockSettings(sampleBlockSettings)

--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onDrawBlock")
end

--Hide the block
function sampleBlock.onDrawBlock(v)
	v.data.set = v.data.set or 0
	blockutils.setBlockFrame(blockID, v.data.set)
end

--Gotta return the library table!
return sampleBlock