--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 26,
	gfxheight = 20,
	width = 16,
	height = 8,
	frames = 32,
	framestyle = 0,
	framespeed = 8, 
	
	speed = 1,
	nohurt=true, -- Disables the NPC dealing contact damage to the player
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nowaterphysics = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall
	nogravity = true,
}

local STATE_FLY = 0
local STATE_WALK = 1

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
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
		data.state = STATE_FLY
		data.random = RNG.randomInt(128, 640)
		data.randomTimerX = 0
		data.randomTimerY = 0
		data.randomTurnX = RNG.randomInt(96, 320)
		data.randomTurnY = RNG.randomInt(96, 320)
		v.speedX = RNG.irandomEntry{-1, 1}
		v.speedY = RNG.irandomEntry{-1, 1}
	end
	
	v.ai2 = v.ai2 + 1
	data.randomTimerX = data.randomTimerX + 1
	data.randomTimerY = data.randomTimerY + 1

	if data.state == STATE_FLY then
		--Randomly fly on the x axis
		if data.randomTimerX >= data.randomTurnX then
			data.randomTimerX = 0
			v.direction = RNG.irandomEntry{-1,1}
			v.speedX = 1 * v.direction
			data.randomTurnX = RNG.randomInt(96, 320)
		end
		
		if v.speedY < 0 then
			data.yDirection = -1
		else
			data.yDirection = 1
		end
		
		v.animationFrame = math.floor(lunatime.tick() / 6) % 4 + 4 + ((v.direction + 1) * 4) + (16 * settings.type)
		
		--Randomly fly on the y axis
		if v.ai2 < data.random and v.ai2 >= 0 then
			if data.randomTimerY >= data.randomTurnY or v.collidesBlockUp then
				data.randomTimerY = 0
				data.yDirection = RNG.irandomEntry{-1,1}
				if v.collidesBlockUp then
					v.speedY = 1
				end
				v.speedY = 1 * data.yDirection
				data.randomTurnY = RNG.randomInt(96, 320)
			end
		elseif v.ai2 >= data.random then
			v.speedY = 1
			if v.collidesBlockBottom then
				data.random = RNG.randomInt(128, 640)
				v.ai2 = 0
				data.state = STATE_WALK
			end
		else
			v.speedY = -0.6
		end
		
		if v.collidesBlockBottom then
			data.random = RNG.randomInt(128, 640)
			v.ai2 = 0
			data.state = STATE_WALK
		end
	else
		v.speedY = v.speedY + Defines.npc_grav
		if v.collidesBlockBottom then
			v.animationFrame = math.floor(lunatime.tick() / 6) % 4 + ((v.direction + 1) * 4) + (16 * settings.type)
			v.ai1 = 0
		else
			v.animationFrame = math.floor(lunatime.tick() / 6) % 4 + 4 + ((v.direction + 1) * 4) + (16 * settings.type)
			v.speedY = 1
			v.ai1 = v.ai1 + 1
		end
		v.speedX = 1 * v.direction
		if v.ai1 >= 64 or v.ai2 >= data.random then
			data.random = RNG.randomInt(128, 640)
			v.ai2 = -64
			data.state = STATE_FLY
			v.speedY = -3
			v.speedX = 0
		end
	end
end

--Gotta return the library table!
return sampleNPC