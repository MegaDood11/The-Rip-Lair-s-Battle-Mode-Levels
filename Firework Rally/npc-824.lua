--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local fireworkFella = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fireworkFellaSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 52,
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

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	iswalker = true,
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
npcManager.setNpcSettings(fireworkFellaSettings)

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
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local framespeed = 8 
local folderPath = "AI/hanabihai/"
local fireworkAI = require(folderPath.."hanabihai")

--local basesprites = Graphics.loadImageResolved("npc-"..npcID.."bottom.png")			-- spritesheet for the base segment (while walking)
--local hurtsprites = Graphics.loadImageResolved("npc-"..npcID.."hurt.png")			-- spritesheet for the base segment (while hurt)
--local segmentsprites = Graphics.loadImageResolved("npc-"..npcID.."segments.png")	-- spritesheet for the different segments, including the top

--Register events
function fireworkFella.onInitAPI()
	npcManager.registerEvent(npcID, fireworkFella, "onTickNPC")
	--npcManager.registerEvent(npcID, fireworkFella, "onTickEndNPC")
	--npcManager.registerEvent(npcID, fireworkFella, "onDrawNPC")
	registerEvent(fireworkFella, "onNPCHarm")
	
	fireworkAI.register(npcID)
end

function fireworkFella.onTickNPC(v)
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
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if data.framecounter then
		if data.framecounter == 0 then
			-- handles the walking animation.
			data.framecounter = framespeed
			if data.frame == 1 then
				data.frame = 0
			else
				data.frame = 1
			end
		else
			data.framecounter = data.framecounter - 1
		end
	end
end

function fireworkFella.onNPCHarm(event,v,harmType,culprit)
	--Misc.dialog(v.id,event,harmType,culprit)
	-- if it gets hit, go into harmed state and shoot fireworks (those are not in this function though)
	if v.id == npcID and harmType ~= HARM_TYPE_LAVA then
		v.data.hit = true	-- to change the sprite
		v.data.baseHeight = 16
		v.data.frame = 0
		v.height = v.data.baseHeight + (v.data.segmentCount) * 10
		v.data.maxfireworktimer = v.data._settings.fireworktimer
		v.data.shootingspeed  = v.data._settings.fireworkspeed
		v:transform(825,true,false)
		event.cancelled = true
	end
end


--Gotta return the library table!
return fireworkFella