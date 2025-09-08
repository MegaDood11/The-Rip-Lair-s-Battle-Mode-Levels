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

	gfxwidth = 76,
	gfxheight = 70,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Frameloop-related
	frames = 9,
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
	isstationary = true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

local STATE_INACTIVE = 0
local STATE_ACTIVE = 1
local STATE_EXPLODE = 2

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
		data.state = STATE_INACTIVE
	end

	if v.heldIndex == 0 then
		
		if v.forcedState ~= 0 then v.friendly = false end
		
		data.timer = data.timer + 1
		
		if data.state == STATE_INACTIVE then
		
			v.animationFrame = 0
			
			if v.collidesBlockBottom then
			else
				data.timer = 0
			end
			
			if data.timer >= 16 then
				data.timer = 0
				data.state = STATE_ACTIVE
				v.friendly = true
			end
			
			for _,p in ipairs(Player.get()) do
				if v.isProjectile and Colliders.collide(p, v) and v:mem(0x12E, FIELD_WORD) <= 0 then
					p:harm()
				end
			end
		elseif data.state == STATE_ACTIVE then
			v.despawnTimer = 180
			if data.timer <= 40 then v.animationFrame = math.floor((data.timer - 1) / 8) % 5 else v.animationFrame = 4 end
			if data.timer >= 80 then
				for _,p in ipairs(Player.get()) do
					for _,n in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
						if v:mem(0x12E, FIELD_WORD) <= 0 then
							if Colliders.collide(p, v) or (Colliders.collide(n, v) and not NPC.config[n.id].powerup and not NPC.config[n.id].iscoin and n.id ~= 951 and n.forcedState == 0 and n.id ~= v.id and not n.friendly) then
								data.timer = 0
								data.state = STATE_EXPLODE
							end
						end
					end
				end
			end
		else
			if data.timer <= 80 then
				v.animationFrame = math.floor(data.timer / 8) % 4 + 5
				if data.timer % 24 == 0 then
					SFX.play("SFX/Mine.wav")
				end
			else
				v.animationFrame = math.floor(data.timer / 6) % 4 + 5
				if data.timer % 12 == 0 then
					SFX.play("SFX/Mine.wav")
				end
				if data.timer >= 96 then
					v:kill(9)
					Explosion.spawn(v.x + v.width * 0.5, v.y + v.height * 0.5, 2)
				end
			end
		end
	else
		v.animationFrame = 0
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