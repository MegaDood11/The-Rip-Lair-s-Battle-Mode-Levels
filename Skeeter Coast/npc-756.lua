--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local skeeter = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local skeeterSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 60,
	gfxwidth = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 44,
	height = 30,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 8,
	--Frameloop-related
	frames = 10,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(skeeterSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=756,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=756,
		[HARM_TYPE_PROJECTILE_USED]=756,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=756,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=756,
	}
);

--Custom local definitions below


--Register events
function skeeter.onInitAPI()
	npcManager.registerEvent(npcID, skeeter, "onTickNPC")
	--npcManager.registerEvent(npcID, skeeter, "onTickEndNPC")
	--npcManager.registerEvent(npcID, skeeter, "onDrawNPC")
	--registerEvent(skeeter, "onNPCKill")
end

function skeeter.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	data.actiontimer = data.actiontimer or 100
	data.frameoffset = data.frameoffset or 0
	
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
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground
	v.animationTimer = 0
	v.speedX = v.speedX * 0.95

	if data.actiontimer > 0 then
		data.actiontimer = data.actiontimer - 1
	end

	if math.floor(v.speedX) == 0 then
		v.speedX = 0
	end

	if v.direction == -1 then
		data.frameoffset = 0
	else
		data.frameoffset = 5
	end

	if v.collidesBlockLeft then
		v.direction = -1
		v.speedX = -7
	else
		if v.collidesBlockRight then
			v.direction = 1
			v.speedX = 7
		end
	end

	if data.actiontimer == 100 then
		if RNG.randomInt(0, 1) == 0 then
			v.direction = -1
		else
			data.frameoffset = 5
			v.direction = 1
		end
	end


	if data.actiontimer > 50 and data.actiontimer < 70 then
		v.animationFrame = (math.floor(lunatime.tick() * 0.125) % 3) + 1 + data.frameoffset
	else
		if data.actiontimer == 50 then
			v.animationFrame = 4 + data.frameoffset
		else
			if data.actiontimer == 0 then
				v.animationFrame = 0 + data.frameoffset
			end
		end
	end

	if data.actiontimer == 50 then
		if RNG.randomInt(0, 2) == 2 or v.dontMove then
			NPC.spawn(757, v.x + 12, v.y + 30)
		else
			v.speedX = RNG.randomInt(5, 10) * v.direction
		end
	end 

	if data.actiontimer == 0 then
		if v.dontMove then
			data.actiontimer = RNG.randomInt(100, 300)
		else
			data.actiontimer = RNG.randomInt(80, 150)
		end
	end
	
end

--Gotta return the library table!
return skeeter