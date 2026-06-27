--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxwidth = 38,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 5,
	framestyle = 1,
	framespeed = 6, --# frames between frame change
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
	
	cliffturn=true,

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
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickEndNPC(v)
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
		data.turnCount = 0
		v.ai1 = 0
		v.ai2 = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if v.direction == -1 then
		data.turnCount = 0
	else
		data.turnCount = sampleNPCSettings.frames
	end
	
	if v.ai1 ~= 1 then
		v.speedX = sampleNPCSettings.speed * v.direction
		
		if v.animationFrame == (sampleNPCSettings.frames - 2) + data.turnCount then
			v.animationFrame = 0 + data.turnCount
		end
	
		if player.x > v.x - 128 and player.x < v.x + v.width + 128 and player.y < v.y + v.height and player.y > v.y - 64 then
			if v.ai1 == 0 and v.collidesBlockBottom then
				if v.direction == -1 and player.x < v.x + (v.width / 2) then
					v.ai1 = 1
					v.speedY = -4
					v.speedX = 0
				elseif v.direction == 1 and player.x > v.x + v.width - (v.width / 2) then
					v.ai1 = 1
					v.speedY = -4
					v.speedX = 0
				end
			end
		elseif v.ai1 == 2 then
			v.ai1 = 0
		end
	else
		v.ai2 = v.ai2 + 1
		v.animationTimer = 1
		
		if v.ai2 < 50 or v.ai2 > 75 then
			v.animationFrame = sampleNPCSettings.frames - 2 + data.turnCount
		else
			v.animationFrame = sampleNPCSettings.frames - 1 + data.turnCount
		end
		
		if v.ai2 == 50 then
			rock = NPC.spawn(761, v.x + (v.width / 2.5), v.y + (v.height / 2.5))
			rock.speedX = 4 * v.direction
			rock.spawnDirection = v.direction
			SFX.play(38)
		end
		
		if v.ai2 == 100 then
			v.ai1 = 2
			v.ai2 = 0
		end
	end
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			turnCount = data.turnCount,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.turnCount = receivedData.turnCount
	end,
}

--Gotta return the library table!
return sampleNPC