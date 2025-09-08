--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 16,
	gfxwidth = 16,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 8,
	height = 8,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	ignorethrownnpcs = true,
	notcointransformable = true,
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.yTimer = 0
		data.moveActive = false
		data.randomValue = 0
		data.timer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.dir = data.dir or RNG.randomInt(0, 1) *2 -1
		data.yTimer = data.yTimer or 0
		data.randomValue = data.randomValue or 0
		data.moveActive = false
		data.timer = data.timer or 0
	end
	
	data.w = 1 * pi/65
	data.timer = data.timer + 1
	
	if not data.moveActive then
		--If not moving then hover in place and do other stuff
		v.speedY = math.sin(lunatime.tick() / 48 * 32) / 4
		v.speedX = 0
		v.ai1 = v.ai1 + 1
		
		if v.ai1 >= RNG.randomInt(0,128) then
			data.randomValue = RNG.randomInt(0,1)
			if data.randomValue == 1 then
				data.moveActive = true
			end
			if v.x < v.spawnX - 16 then
				data.dir = DIR_RIGHT
			elseif v.x > v.spawnX + 16 then
				data.dir = DIR_LEFT
			else
				data.dir = RNG.randomInt(0, 1) * 2-1
			end
		end
	else
	
		--Think of this as a "movement timer".
		v.ai2 = v.ai2 + 1
		--Don't let it fly too far out of its spawn boundaries or they'll all get separated.
		if v.ai2 >= RNG.randomInt(1,64) then
			v.ai2 = 0
			v.ai1 = 0
			data.timer = 0
		end
	
		--Move
		data.yTimer = data.yTimer + 1
		if data.yTimer >= RNG.randomInt(4,24) then
			data.moveActive = false
			data.yTimer = 0
		end
	
		if v.x < v.spawnX - 16 then
			data.dir = DIR_RIGHT
		elseif v.x > v.spawnX + 16 then
			data.dir = DIR_LEFT
		end
	
		--Make them move up and down
		if v.y < v.spawnY - 32 or v.y > v.spawnY + 32 then
			if v.y < v.spawnY - 32 then
				v.speedY = 2.5 * 50 * data.w * cos(data.w*data.timer)
			else
				v.speedY = 2.5 * 50 * -data.w * cos(data.w*data.timer)
			end
		else
			v.speedY = 2.5 * 50 * (data.w * data.dir) * cos(data.w*data.timer)
		end
		v.speedX = 100 * data.w * sin(data.w*data.timer) * data.dir
	end
end

--Gotta return the library table!
return sampleNPC