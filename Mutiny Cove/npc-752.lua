--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local bird = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local birdSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 40,
	gfxwidth = 52,
	width = 40,
	height = 32,
	frames = 5,
	framestyle = 1,
	framespeed = 8,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(birdSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=npcID,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=npcID,
		--[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=npcID,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function bird.onInitAPI()
	npcManager.registerEvent(npcID, bird, "onTickEndNPC")
	npcManager.registerEvent(npcID, bird, "onDrawNPC")
	npcManager.registerEvent(npcID, bird, "onPostExplosionNPC")
	registerEvent(bird, "onNPCKill")
end

function bird:onPostExplosionNPC(explosion, player)
	if Colliders.collide(explosion.collider,self) then
		self.data.explode = true
	end
end

function bird.onNPCKill(e, v, r)
	if v.id ~= npcID then return end
	if not v.data.explode then
		if r == HARM_TYPE_JUMP or r == HARM_TYPE_NPC or r == HARM_TYPE_FROMBELOW or r == HARM_TYPE_PROJECTILE_USED or r == HARM_TYPE_HELD or r == HARM_TYPE_TAIL then
			Effect.spawn(npcID, v.x, v.y + v.height * 0.5, math.clamp(v.direction + 2, 1, 2))
		end
	else
		Effect.spawn(800, v.x - v.width * 0.5, v.y - v.height * 0.5)
		Effect.spawn(772, v.x - v.width * 0.5, v.y - v.height * 0.5)
		SFX.play("SFX/Parrot.wav")
	end
end

function bird.onTickEndNPC(v)
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
		data.timer = 0
	end
	
	data.timer = data.timer + 1
	data.flyTimer = (data.flyTimer or 0) + 1
	v.speedX = 3 * v.direction
	
	if data.flyTimer >= 1536 then
		v.speedX = 0
		v.speedY = -3
		v.animationFrame = math.floor(lunatime.tick() / 4) % 4
	else
		v.despawnTimer = 180
		if data.timer >= 96 then
			v.animationFrame = 4
			if data.timer == 96 then
				SFX.play(RNG.irandomEntry{"SFX/Poop 1.wav","SFX/Poop 2.wav","SFX/Poop 3.wav"})
				NPC.spawn(npcID + 1, (v.x) + (v.direction + 1) * 8, v.y + v.height, player.section, false)
			end
			if data.timer >= 112 then
				data.timer = 0
			end
		else
			v.animationFrame = math.floor(lunatime.tick() / 4) % 4
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = birdSettings.frames
	});
	
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			flyTimer = data.flyTimer,
			timer = data.timer,
			frame = data.frame,
			explode = data.explode,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.flyTimer = receivedData.flyTimer
		data.timer = receivedData.timer
		data.frame = receivedData.frame
		data.explode = receivedData.explode
	end,
}

--Gotta return the library table!
return bird