--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local butterfly = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local butterflySettings = {
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
	frames = 36,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
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
npcManager.setNpcSettings(butterflySettings)

--Register events
function butterfly.onInitAPI()
	npcManager.registerEvent(npcID, butterfly, "onTickEndNPC")
end

function butterfly.onTickEndNPC(v)
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
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		if settings.random then
			settings.color = RNG.randomInt(0,8)
		end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	data.timer = data.timer + 1
	
	if settings.color == nil then
		settings.color = 0
	end
	
	--Control animation
	if v.direction == DIR_LEFT then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 2 + (4 * settings.color)
	else
		v.animationFrame = math.floor(lunatime.tick() / 4) % 2 + (4 * settings.color + 2)
	end
	
	--Turn if data.timer reaches a certain amount
	if data.timer >= 144 then
		data.timer = 0
		v.direction = -v.direction
	end
	
	--Movement
	v.speedX = 0.5 * v.direction
	v.speedY = math.sin(lunatime.tick()/12)*1
end

--Gotta return the library table!
return butterfly