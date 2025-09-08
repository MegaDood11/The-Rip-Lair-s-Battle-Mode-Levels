--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local rabbit = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local rabbitSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 7,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
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
	randomDir = false,
}

--Applies NPC settings
npcManager.setNpcSettings(rabbitSettings)

local STATE_LOOK = 0
local STATE_RUN = 1

--Register events
function rabbit.onInitAPI()
	npcManager.registerEvent(npcID, rabbit, "onTickEndNPC")
end

function rabbit.onTickEndNPC(v)
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
		data.state = STATE_RUN
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
		data.state = STATE_RUN
		if settings.random then
			settings.color = RNG.randomInt(0,1)
		end
		data.randomDir = RNG.randomInt(0,1)
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.timer = 0
		data.state = STATE_RUN
	end
	
	if v.collidesBlockBottom then
		data.timer = data.timer + 1
	end
	
	if v.dontMove then
		data.state = STATE_LOOK
	end
	
	if data.state == STATE_RUN then
		v.speedX = 1.5 * v.direction
		if data.timer >= RNG.randomInt(256, 384) then
			v.speedX = 0
			data.timer = 0
			data.state = STATE_LOOK
			data.randomDir = RNG.randomInt(0,1)
		end
	else
		v.animationFrame = 0
		if data.timer >= RNG.randomInt(192,384) then
			data.state = STATE_RUN
			data.timer = 0
			if rabbitSettings.randomDir then
				if data.randomDir == 0 then
					v.direction = -v.direction
				end
			end
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = rabbitSettings.frames
	});
	
end
--Gotta return the library table!
return rabbit