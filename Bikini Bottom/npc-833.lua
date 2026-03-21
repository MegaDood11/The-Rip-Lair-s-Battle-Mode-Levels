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
	gfxwidth = 66,
	gfxheight = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 13,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	nohurt=false, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = false,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	
	--Various interactions
	jumphurt = false, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onPostNPCKill")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onPostNPCKill(v, reason)
	if v.id ~= npcID then return end
	Effect.spawn(npcID, v.x - v.width * 0.325, v.y, v.data.state + 1)
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	if v.id == npcID and culprit then
		local data = v.data
		if type(culprit) == "Player" and reason == HARM_TYPE_JUMP then
			SFX.play(2)
			if data.electric then
				eventObj.cancelled = true
				culprit:harm()
				return
			end
		
			if data.state == 0 then
				data.state = 1
				data.hit = 48
				v.friendly = true
				eventObj.cancelled = true
			else
				SFX.play(59)
				for i = -1,1 do
					local n = NPC.spawn(33, v.x + v.width * 0.25, v.y - v.height * 1.5, player.section, false)
					n.ai1 = 1
					n.speedY = -8
					n.speedX = 2 * i
				end
			end
		else
			SFX.play(9)
		end
	end
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
		data.state = 0
		data.timer = 0
		data.timer2 = 0
		data.electric = false
	end
	
	data.timer = data.timer + 1
	
	if not data.electric then
		if data.timer >= 96 then
			data.timer = 0
			data.electric = true
		end
		
		v.animationFrame = math.floor(data.timer / 6) % 4 + (data.state * 6)
		
	else
		if data.timer >= 64 then
			data.timer = 0
			data.electric = false
		end
		
		v.animationFrame = math.floor(data.timer / 4) % 2 + 4 + (data.state * 6)
		
	end
	
	if data.hit then
		data.hit = data.hit - 1
		if data.hit <= 0 then data.hit = nil end
		v.animationFrame = 12
		v.speedY = 0
		data.timer = 0
		data.electric = true
		return
	end
	
	v.friendly = false
	data.timer2 = data.timer2 + 1
	v.speedY = math.sin(data.timer2 / 20) * 0.325
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			timer = data.timer,
			timer2 = data.timer2,
			state = data.state,
			electric = data.electric,
			hit = data.hit,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end
		data.timer = receivedData.timer
		data.timer2 = receivedData.timer2
		data.state = receivedData.state
		data.electric = receivedData.electric
		data.hit = receivedData.hit
	end,
}

--Gotta return the library table!
return sampleNPC