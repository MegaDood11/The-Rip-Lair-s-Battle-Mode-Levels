--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local dragonfly = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local dragonflySettings = {
	id = npcID,
	--Sprite size
	gfxheight = 16,
	gfxwidth = 16,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 16,
	height = 16,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 24,
	framestyle = 0,
	framespeed = 2, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
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
npcManager.setNpcSettings(dragonflySettings)

--Register events
function dragonfly.onInitAPI()
	npcManager.registerEvent(npcID, dragonfly, "onTickEndNPC")
end

function dragonfly.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	v.friendly = true
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.countTimer = -1
		data.gradSpeed = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.countTimer = data.countTimer or -1
		data.gradSpeed = data.gradSpeed or 0
		if settings.random then
			settings.color = RNG.randomInt(0,5)
		end
	end

	if settings.color == nil then
		settings.color = 0
	end

	v.speedY = math.sin(lunatime.tick() / 2.5 * 0.5)
	
	v.speedX = math.abs(data.gradSpeed) * v.direction
	
	v.animationFrame = math.floor(lunatime.tick() / 2) % 2 + (v.direction + 1) + (settings.color * 4)
	
	if data.gradSpeed > 0 then
		data.gradSpeed = math.abs(data.gradSpeed) - 0.09
	else
		data.gradSpeed = 0
	end
	
	if v.speedX == 0 then
		data.timer = data.timer + 1
		if data.timer >= 32 then
			data.timer = 0
			data.gradSpeed = 2
			data.countTimer = data.countTimer + 1
		end
	end
	
	--Turn if data.timer reaches a certain amount
	if data.countTimer >= 4 then
		data.countTimer = 0
		v.direction = -v.direction
	end
end

--Gotta return the library table!
return dragonfly