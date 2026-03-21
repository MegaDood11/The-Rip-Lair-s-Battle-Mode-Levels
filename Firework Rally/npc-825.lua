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
	height = 46,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 0,
	score = 0,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=true,
	grabtop=true,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = true,
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
	--isshell = true,

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
local fireworksflySFX = folderPath .. "firework_fly.ogg"
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
	--Execute main AI.
	if not data.fireworktimer then
		if data.segmentCount then
			-- initialize required vars. Also resize the npc since transforming reverts the size change!
			v.height = v.data.baseHeight + (v.data.segmentCount) * 10	-- set the height
			v.y = v.y - (v.height - 46)
			data.fireworktimer = data.maxfireworktimer
			if not data.maxfireworktimer then
				data.fireworktimer = data._settings.fireworktimer
				data.maxfireworktimer = data._settings.fireworktimer
			end
		end
		if not data.shootingspeed then
			if data._settings.fireworkspeed then
				data.shootingspeed = data._settings.fireworkspeed
			end
		end
	else
		if data.fireworktimer > 0 then
			data.fireworktimer = data.fireworktimer - 1
			if data.fireworktimer % 8 == 0 then
				local effect = Effect.spawn(74,v.x + v.width * 0.5 - 4,v.y)
				effect.y = v.y
				effect.speedY = -6
				effect.speedX = math.random(-2,2)
			end
			data.hit = true		-- set here because it breaks stuff if set to true too early
		else
			data.fireworktimer = data.maxfireworktimer
			local firework = v.spawn(823,v.x+v.width*0.5,v.y + (v.height) - 16 + 5 - (data.segmentCount - 1)* 10,v.section,false,true)  --Summon the work of fire.
			firework.speedY = -data.shootingspeed
			if not (data.segmentType[data.segmentCount] == 0) then				-- assigns the colour (and offset) of the top most segment to the firework.
				firework.data.colourType = data.segmentType[data.segmentCount]
				firework.data.colour = data.segmentColor[data.segmentCount]
			else																-- skips the top most if it's actually the very top (as it has no colour)
				firework.data.colourType = data.segmentType[data.segmentCount-1]
				firework.data.colour = data.segmentColor[data.segmentCount-1]
			end
			firework.speedX = 0
			
			SFX.play(fireworksflySFX)
			fireworkAI.explodeSegment(v)
			v.speedY = -2
		end
	end

end

function fireworkFella.onNPCHarm(event,v,harmType,culprit)
	-- if it gets hit, go into harmed state and shoot fireworks (they are a seperate npc)
	if v.id == npcID and harmType ~= HARM_TYPE_LAVA then
		if v.collidesBlockBottom then
			v.speedY = -3
		end
		Audio.playSFX(2)
		event.cancelled = true
	end
end


--Gotta return the library table!
return fireworkFella