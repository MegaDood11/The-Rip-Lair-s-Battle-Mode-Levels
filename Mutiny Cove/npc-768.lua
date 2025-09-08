--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")
local battlePlayer = require("scripts/battlePlayer")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 30,
	gfxheight = 30,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 30,
	height = 30,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,
	
	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = true, -- If true, the NPC will not die when released in a wall
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onNPCKill(e,v,r)
	if v.id == npcID then
		Effect.spawn(133, v.x, v.y)
		SFX.play("SFX/Land.wav")
	end
end

function sampleNPC.onTickNPC(v)
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
		data.timer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v.isProjectile and v.ai1 == 0 then
		if not data.split then
			data.split = true
			for i = 1,7 do
				local n = NPC.spawn(npcID, v.x, v.y, player.section, false)
				n.speedX = v.speedX + RNG.random(-3, 3)
				n.speedY = v.speedY + RNG.random(-3, 3)
				n.isProjectile = true
				n.ai1 = 1
				n:mem(0x130, FIELD_WORD, v:mem(0x130, FIELD_WORD))
				n:mem(0x12E, FIELD_WORD, 30)
			end
		end
	end
		
	if v.heldIndex == 0 and v.forcedState == 0 then
	
		for _,p in ipairs(Player.get()) do
			if not v.friendly and Colliders.collide(p, v) and v:mem(0x12E, FIELD_WORD) <= 0 then
				p:harm()
			end
		end

	
		data.timer = data.timer + 1
		for _,p in ipairs(Player.get()) do
			if data.timer >= 8 then
				if (Colliders.collide(p,v) and p.forcedState == 0 and p.deathTimer <= 0) or (v.collidesBlockBottom or v.collidesBlockUp or v.collidesBlockLeft or v.collidesBlockRight) then
					v:kill(9)
				end
			end
		end
	end
	
	for _,n in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
		if (n.id >= 754 and n.id <= 765) and v.isProjectile then
			if n.data.state == 0 then
				SFX.play(NPC.config[n.id].sound)
				n.data.state = 1
				n.ai2 = 1
				n.speedX = 4 * v.direction
				n.speedY = -5
				n.ai3 = 5
			end
		end
	end
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			MutinyLevelSplashSound = data.MutinyLevelSplashSound,
			split = data.split,
			timer = data.timer,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.MutinyLevelSplashSound = receivedData.MutinyLevelSplashSound
		data.split = receivedData.split
		data.timer = receivedData.timer
	end,
}

--Gotta return the library table!
return sampleNPC