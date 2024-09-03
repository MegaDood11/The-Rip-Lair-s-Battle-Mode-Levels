--Blockmanager is required for setting basic Block properties
local blockManager = require("blockManager")
local blockutils = require "blocks/blockutils"

local effect = Particles.Emitter(0,0, Misc.resolveFile("p_tractorBeam.ini"))

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
	sizable = true, --sizable block
	passthrough = true, --no collision
	--bumpable = false, --can be hit from below
	--lava = false, --instakill
	--pswitchable = false, --turn into coins when pswitch is hit
	--smashable = 0, --interaction with smashing NPCs. 1 = destroyed but stops smasher, 2 = hit, not destroyed, 3 = destroyed like butter

	--floorslope = 0, -1 = left, 1 = right
	--ceilingslope = 0,

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

--Register events
function sampleBlock.onInitAPI()
	blockManager.registerEvent(blockID, sampleBlock, "onTickBlock")
	--registerEvent(sampleBlock, "onBlockHit")
end

function sampleBlock.onTickBlock(v)
    -- Don't run code for invisible entities
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data

	local t = Player.get()
	for i=1,#t do
		local p = t[i]
		if Colliders.collide(p, v) then
			p.data.BumpedHeadOnAlienShip = p.data.BumpedHeadOnAlienShip + 0.025
			p.speedY = math.max(p.data.BumpedHeadOnAlienShip, 0.2)
		else
			p.data.BumpedHeadOnAlienShip = 0
		end
	end
	
	for _,n in ipairs(NPC.get()) do
		if Colliders.collide(n, v) and n.id ~= 675 then
			n.speedY = n.speedY + 0.25
			if n.id == 17 then n.y = n.y + 3 end
			if n.collidesBlockUp then n.speedY = 8 end
		end
	end
	
	effect:Draw(0)
	effect.x = RNG.randomInt(-199584, -199136)
	effect.y = RNG.randomInt(-200768, -200032)
	effect:setParam("speedY", 50)
end

--Gotta return the library table!
return sampleBlock