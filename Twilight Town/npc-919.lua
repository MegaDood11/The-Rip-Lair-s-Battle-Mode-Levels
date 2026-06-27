--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local particles = require("particles")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 70,
	gfxheight = 54,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	frames = 13,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes
	nowaterphysics = true,
	
	deathEffect = 789,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

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
	}
);

local STATE_LURK = 0
local STATE_JUMP = 1
local STATE_CHASE = 2

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

--Todo
--Make the npc
--Make it so if data.ground then any state other than STATE_LURK forces it to go intom its enter ground animation

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
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
		if v.data._settings.ground then data.ground = true end
		
		if v.data._settings.chase then
			data.chase = true
			data.state = STATE_CHASE
		else
			data.state = STATE_LURK
			v.y = v.y - (v.height - 4)
			v.height = 4
			data.particle = particles.Emitter(0,0, Misc.resolveFile("shadowDust.ini"))
			data.particle:Attach(v)
		end
		
		data.friendly = v.friendly
		data.timer = 0
		data.timer2 = 0
		data.offGround = 0
		data.chaseSpeed = 0
		
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		data.state = STATE_CHASE
	end
	
	data.timer = data.timer + 1
	data.timer2 = data.timer2 + 1
	
	if data.timer2 >= 896 then
		v:kill(9)
		for i = 0, 3 do
			local e = Effect.spawn(NPC.config[v.id].deathEffect, v.x + v.width * 0.5, v.y + v.height * 0.25, i + 1, v.id, false)
			e.speedX = RNG.irandomEntry{-2,-1.5,-1,1,1.5,2}
			e.speedY = RNG.irandomEntry{-2,-1.5,-1,1,1.5,2}
		end
	end
	
	if data.state == STATE_LURK then
		
		--Thing to check if its off the ground or going down a slope
		if v.collidesBlockBottom then
			data.offGround = 0
		else
			data.offGround = data.offGround + 1
		end
		
		--Follow the plyer
		if data.offGround <= 1 then

			v.animationFrame = 0
			v.friendly = true
			v.speedX = 2.5 * v.direction
			
			--Launch out at the trapped player!
			if math.abs(v.x + v.width * 0.5 - plr.x) <= v.width / 2 and (plr.y <= v.y + v.height and plr.y >= v.y - 192) then
				v.friendly = data.friendly
				data.timer = 0
				data.state = STATE_JUMP
				v.speedX = 0
				v.speedY = -8
				data.timer = 0
				data.offGround = 0
				SFX.play("heartless_resurface.wav")
				local e = Effect.spawn(NPC.config[v.id].deathEffect, v.x + v.width * 0.5, v.y + v.height * 0.25)
				e.speedX = RNG.random(-1,1)
				e.speedY = RNG.random(-1,1)
				v.height = sampleNPCSettings.height
				v.y = v.y - (sampleNPCSettings.height - 4)
			end
			
			--Chase the nearestPlayer
			if lunatime.tick() % 40 == 0 then
				npcutils.faceNearestPlayer(v)
			end
			
			if data.timer < 0 then
				v.animationFrame = 11
				v.speedX = 0
			end
			
			
			
		else
			--Fall off a ledge
			v.friendly = data.friendly
			v.speedX = 0
			v.animationFrame = 10
			data.timer = -4
		end
	elseif data.state == STATE_JUMP then
		--Lunge at the player
		if v.collidesBlockBottom then
			--Go back into the ground if needs be
			if data.ground then
				v.friendly = true
				if data.timer <= 4 then
					v.animationFrame = 11
				else
					data.state = STATE_LURK
					data.timer = 0
				end
			else
				data.timer = 0
				data.state = STATE_CHASE
				npcutils.faceNearestPlayer(v)
			end
		else
			if v.speedY < 0 then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 4 + 1
			else
				v.animationFrame = 5
			end
			data.timer = 0
		end
	else
		if data.chase then
			--Stand for a bit before chasing if the right setting is set to true
			if data.timer <= 32 then
				if math.abs(plr.x - v.x) <= 192 then
					data.timer = 33
				end
				v.animationFrame = 12 + ((v.direction + 1) * sampleNPCSettings.frames / 2)
			else
				data.chase = false
			end
		else
		
			v.speedX = data.chaseSpeed
			
			--Chase the player!
			if v.x <= plr.x then
				v.animationFrame = math.floor(lunatime.tick() / 6) % 4 + 6 + sampleNPCSettings.frames
				data.chaseSpeed = math.clamp(data.chaseSpeed + 0.125, -3, 3)
			else
				v.animationFrame = math.floor(lunatime.tick() / 6) % 4 + 6
				data.chaseSpeed = math.clamp(data.chaseSpeed - 0.125, -3, 3)
			end
		end
	end
	
	if data.state ~= STATE_CHASE then
		-- animation controlling
		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
	end
end

--Emit some particles
function sampleNPC.onDrawNPC(v)
	if v.data.particle and (v.data.state == STATE_LURK and v.data.offGround <= 1 and v.data.timer >= 0) then
		v.data.particle:Draw(-50)
	end
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_OFFSCREEN then return end
	local data = v.data
	
	--Specifically for when it jumps up from the ground
	if data.state == STATE_JUMP and v.speedY < 0 then
		if reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP then
			eventObj.cancelled = true
			if reason == HARM_TYPE_JUMP then
				culprit:harm()
			else
				SFX.play(2)
			end
			return
		end
	end
	
	--Play a sound and spawn an effect when it dies
	for i = 0, 3 do
		SFX.play("heartless_kill.wav")
		local e = Effect.spawn(NPC.config[v.id].deathEffect, v.x + v.width * 0.5, v.y + v.height * 0.25, i + 1, v.id, false)
		e.speedX = RNG.irandomEntry{-2,-1.5,-1,1,1.5,2}
		e.speedY = RNG.irandomEntry{-2,-1.5,-1,1,1.5,2}
	end
	
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			initialized = data.initialized,
			ground = data.ground,
			chase = data.chase,
			state = data.state,
			friendly = data.friendly,
			timer = data.timer,
			timer2 = data.timer2,
			offGround = data.offGround,
			chaseSpeed = data.chaseSpeed,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.initialized = receivedData.initialized
		data.ground = receivedData.ground
		data.chase = receivedData.chase
		data.state = receivedData.state
		data.friendly = receivedData.friendly
		data.timer = receivedData.timer
		data.timer2 = receivedData.timer2
		data.offGround = receivedData.offGround
		data.chaseSpeed = receivedData.chaseSpeed
	end,
}

--Gotta return the library table!
return sampleNPC