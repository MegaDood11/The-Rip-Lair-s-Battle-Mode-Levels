--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")
local boneBlocks = require("boneBlocks")

--Create the library table
local sampleBlock = {}
--BLOCK_ID is dynamic based on the name of the library file
local blockID = BLOCK_ID

--Defines Block config for our Block. You can remove superfluous definitions.
local sampleBlockSettings = {
	id = blockID,
	--Frameloop-related
	frames = 1,
	framespeed = 8, --# frames between frame change

	--Identity-related flags:
	--semisolid = false, --top-only collision
	--sizable = false, --sizable block
	--passthrough = false, --no collision
	bumpable = true, --can be hit from below
	--lava = false, --instakill
	--pswitchable = false, --turn into coins when pswitch is hit
	--smashable = 0, --interaction with smashing NPCs. 1 = destroyed but stops smasher, 2 = hit, not destroyed, 3 = destroyed like butter

	--floorslope = 0, -1 = left, 1 = right
	--ceilingslope = 0,

	-- bone block specific settings:
	chainDelay = 6,		-- the delay in frames of each adjasoned block triggering
	launchHeight = -8,	-- the speed of a block when hit
	
	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies blockID settings
blockManager.setBlockSettings(sampleBlockSettings)

--Register the vulnerable harm types for this Block. The first table defines the harm types the Block should be affected by, while the second maps an effect to each, if desired.

--Custom local definitions below


--Register events
function sampleBlock.onInitAPI()
	--blockManager.registerEvent(blockID, sampleBlock, "onTickEndBlock")
	--registerEvent(sampleBlock, "onPostBlockHit")
	boneBlocks.register(blockID)
end

function sampleBlock.onPostBlockHit(v, fromUpper)
	if v.id == BLOCK_ID then
		-- Uncomment the registerEvent for onPostBlockHit to get started adding hit reactions to your block here
	end
end

function sampleBlock.onTickEndBlock(v)
    -- Don't run code for invisible entities
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	
	-- Uncomment the registerEvent for onTickEndBlock to get started adding per-tick code for your block here
end

--Gotta return the library table!
return sampleBlock