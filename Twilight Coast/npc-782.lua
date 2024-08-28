--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local crab = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local crabSettings = {
	id = npcID,
	gfxheight = 56,
	gfxwidth = 48,
	width = 32,
	height = 32,
	gfxoffsetx = -8,
	frames = 4,
	framestyle = 1,
	framespeed = 8, 
	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false,
	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	
	rock = 784,
	sand = 783,
}

--Applies NPC settings
npcManager.setNpcSettings(crabSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below

local STATE_WAIT = 0
local STATE_PREPARE = 1
local STATE_THROW = 2

--Register events
function crab.onInitAPI()
	npcManager.registerEvent(npcID, crab, "onTickEndNPC")
end

function getAnimationFrame(v) 
    local data = v.data
	local frame = 0
	
	if data.state == STATE_WAIT then
		 if lunatime.tick() % 14 < 7 then
				frame = 0
			elseif lunatime.tick() % 14 < 15 then
				frame = 1
		end
	end

	if data.state == STATE_PREPARE then
		if not v.data._settings.throwRock then
			frame = 2
		else
			frame = 3
		end
	end
	
	if data.state == STATE_THROW then
		frame = 1
	end

    v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})
end 


function crab.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	getAnimationFrame(v)
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_WAIT
		data.timer = data.timer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	data.timer = data.timer + 1

	if data.timer >= v.data._settings.delay + 39 and data.timer <= v.data._settings.delay + 49 and v.data._settings.noMove == false then
		v.x = v.x - 3 * v.direction
	else
		v.speedX = 0
	end

	if data.timer == v.data._settings.delay then
		data.state = STATE_PREPARE
	elseif data.timer == v.data._settings.delay + 32 and v.collidesBlockBottom then
		v.speedY = -6
	elseif data.timer == v.data._settings.delay + 38 then
		data.state = STATE_THROW
	elseif data.timer == v.data._settings.delay + 39 then
		if v.data._settings.throwRock then
			local n = NPC.spawn(crabSettings.rock, v.x + v.width * 0.5 * (1.5 + v.direction), v.y + 0.5 * v.height, player.section, false, true)
			n.speedX = v.data._settings.xSpeed * v.direction
			n.speedY = v.data._settings.ySpeed
			n.ai2 = v.data._settings.ySpeed
			if v.data._settings.projGrav then
				n.ai1 = 1
			end
		else
			local e = NPC.spawn(crabSettings.sand, v.x + v.width * 0.5 * (1.5 + v.direction), v.y + 0.5 * v.height, player.section, false, true)
			e.speedX = v.data._settings.xSpeed * v.direction
			e.speedY = v.data._settings.ySpeed
			e.ai2 = v.data._settings.ySpeed
			if v.data._settings.projGrav then
				e.ai1 = 1
			end
		end
		SFX.play(25)
	elseif data.timer > v.data._settings.delay + 49 then
		data.state = STATE_WAIT
		data.timer = 0
	end
end

--Gotta return the library table!
return crab