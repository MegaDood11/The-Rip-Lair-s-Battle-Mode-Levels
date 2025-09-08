--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 68,
	gfxheight = 154,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 48,
	--Frameloop-related
	frames = 8,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
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

local STATE_LAUNCH = 0
local STATE_DRIFT = 1

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

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
		data.timer = 0
		data.state = STATE_LAUNCH
	end
		
	if v.heldIndex == 0 then
		for _,p in ipairs(Player.get()) do
			for _,n in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
				if v:mem(0x12E, FIELD_WORD) <= 0 then
					if Colliders.collide(p, v) or (Colliders.collide(n, v) and not NPC.config[n.id].powerup and not NPC.config[n.id].iscoin and n.id ~= 951 and n.forcedState == 0 and n.id ~= v.id) or (v.collidesBlockBottom or v.collidesBlockUp or v.collidesBlockLeft or v.collidesBlockRight) then
						v:kill(9)
						Explosion.spawn(v.x + v.width * 0.5, v.y + v.height * 0.5, 2)
					end
				end
			end
		end
		
		if data.state == STATE_LAUNCH then
			data.timer = data.timer + 1
			v.animationFrame = math.floor(data.timer / 8) % 4
			v.speedX = 0
			v.speedY = math.clamp(-10 + (data.timer * 0.125), -8, 0)
			v.isProjectile = false
			if v.speedY >= 0 and v.forcedState == 0 then
				data.timer = 0
				data.state = STATE_DRIFT
			end
		else
			v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 4
			v.despawnTimer = 180
			v.speedY = math.clamp(v.speedY + 0.125, 0, 1.25)
			npcutils.faceNearestPlayer(v)
			data.timer = math.clamp(data.timer + 0.125 * v.direction, -3, 3)
			v.speedX = data.timer
			if lunatime.tick() % 80 == 0 then SFX.play("SFX/Flap.wav") end
		end
	else
		v.animationFrame = math.floor(data.timer / 8) % 4
		data.timer = 0
		data.state = 0
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
			timer = data.timer,
			MutinyLevelSplashSound = data.MutinyLevelSplashSound,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.state = receivedData.state
		data.timer = receivedData.timer
		data.MutinyLevelSplashSound = receivedData.MutinyLevelSplashSound
	end,
}

--Gotta return the library table!
return sampleNPC