--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxwidth = 64,
	gfxheight = 50,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1.5,
	luahandlesspeed = true,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	staticdirection = true,

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
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		if data.fblock ~= nil then
			if data.fblock.isValid then
				data.fblock:delete()
			end
		end
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		v.friendly = true
		v.ai2 = 1
		v.ai3 = 0
		v.ai5 = 100
		
		data.fblock = Block.spawn(data._settings.id, v.x, v.y)
		v.ai4 = data.fblock.id
		
		v.speedX = sampleNPCSettings.speed * v.direction
		
		if data._settings.invisible then
			data.fblock:mem(0x5A, FIELD_BOOL, true)
		end
		
		if v.ai1 ~= 0 then
			data.fblock.contentID = v.ai1 + 1000
		end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	v.speedY = math.clamp(v.speedY - .05 * v.ai2, -1.5, 1.5)
	data.fblock.x = v.x
	data.fblock.y = v.y
	
	v.ai3 = v.ai3 + 1
	if v.ai3 == 25 then
		v.ai2 = v.ai2 * -1
		v.ai3 = -25
	end
	
	if data._settings.movement == 1 then
		v.ai5 = v.ai5 + 1
		if v.ai5 == 200 then
			v.direction = -v.direction
			v.ai5 = -200
		end
		
		v.speedX = math.clamp(v.speedX + .01 * v.direction, sampleNPCSettings.speed * -1, sampleNPCSettings.speed)
	else
		v.speedX = sampleNPCSettings.speed * v.direction
	end
	
	
	
	data.fblock.speedX = v.speedX
	data.fblock.speedY = v.speedY
	
	if v.ai4 ~= data.fblock.id or data.fblock.layerName == "Destroyed Blocks" or data.fblock == nil then
		if v.speedY < -.5 then
			data.fblock.y = data.fblock.y + 1
		end
		data.fblock.speedX = 0
		data.fblock.speedY = 0
		v:kill(HARM_TYPE_OFFSCREEN)
	end
end

function sampleNPC.onDrawNPC(v)
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		return
	end
	
	utils.drawNPC(v, {yOffset = sampleNPCSettings.height - v.height, priority = -75})
	utils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC