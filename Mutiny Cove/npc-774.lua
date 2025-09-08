--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 38,
	gfxheight = 62,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 24,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	nowaterphysics = true,

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = true,

	grabside=false,
	grabtop=false,
	ishot = true,
	durability = 1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability
	
	--Emits light if the Darkness feature is active:
	lightradius = 80,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

local STATE_FIRE = 0
local STATE_SUMMON_FIRE = 1

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		if data.state == nil then data.state = 0 end
	end
	
	if data.state == 0 then
		--Fly through the air, when touching the ground spawn fire
		if v.collidesBlockBottom then
			v.speedX = 0
			local n = NPC.spawn(npcID, v.x, v.y, player.section, false)
			n.direction = -v.direction
			n.speedX = 2 * n.direction
			v.speedX = 2 * v.direction
			n.data.state = 1
			data.state = 1
			n.data.stayDir = n.direction
			data.stayDir = v.direction
		end
	else
		v.friendly = true
		v.ai2 = v.ai2 + 1
		--Make it invisible and move it along the ground
		if v.direction ~= data.stayDir then
			v:kill(9)
		end
		v.animationFrame = -1
		--Spawn fire as it moves
		if v.ai2 % 16 == 1 then
			NPC.spawn(npcID + 1, v.x, v.y, player.section, false)
		end
		if not v.collidesBlockBottom then v:kill(9) end
	end
end


onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			state = data.state,
			stayDir = data.stayDir,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.state = receivedData.state
		data.stayDir = receivedData.stayDir
	end,
}

--Gotta return the library table!
return sampleNPC