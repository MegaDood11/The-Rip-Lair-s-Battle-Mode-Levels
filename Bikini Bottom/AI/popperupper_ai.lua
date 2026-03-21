
--[[
					Popper-Uppers by MrNameless
		A static NPC that starts to shake and gets set on shooting it's
			top off within a set time frame upon being picked up.
			
	CREDITS:
	NCR Sound Effect - Provided the various "Boing" SFX (https://www.youtube.com/watch?v=gULoMb7YKhI)
	Nickelodeon - Company behind "SpongeBob SquarePants"
]]--

local npcManager = require("npcManager")
local utils = require("npcs/npcutils")
local smallSwitch = require("npcs/ai/smallswitch")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

local ai = {}

local coloredSwitches = table.map{451,452,453,454,606,607}

function ai.registerLauncher(id)
	npcManager.registerEvent(id, ai, "onTickNPC","onTickLauncher")
	npcManager.registerEvent(id, ai, "onDrawNPC","onDrawLauncher")
	registerEvent(ai, "onNPCHarm")
end
	
function ai.registerProjectile(id)
	npcManager.registerEvent(id, ai, "onTickEndNPC","onTickEndProjectile")
end

function ai.onNPCHarm(eventObj, v, reason, culprit)

	if v.id ~= 828 then return end
	if reason ~= HARM_TYPE_JUMP then return end
	
	local data = v.data
	eventObj.cancelled = true
	
	SFX.play(2)
	
	if not data.isShaking then
		SFX.play(89)
		data.isShaking = true
		if v.heldIndex < 0 then
			data.shakeTimer = math.min(data.shakeTimer,79)
		end
	end
end

function ai.onTickLauncher(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0	--If despawned
	or v.forcedState > 0	--Various forced states
	then
		--Reset our properties, if necessary
		if v.despawnTimer <= 0 then data.initialized = false end
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.isShaking = false
		data.shakeTimer = NPC.config[v.id].timeUntilLaunch
		data.initialized = true
	end
	
	if v.heldIndex ~= 0 and not data.isShaking then
		SFX.play(89)
		data.isShaking = true
		if v.heldIndex < 0 then
			data.shakeTimer = math.min(data.shakeTimer,79)
		end
	end	
	
	if not data.isShaking then return end
	data.shakeTimer = math.max(data.shakeTimer - 1,0)
	
	-- handles the ticking SFX
	if data.isShaking and ((data.shakeTimer <= 80 and data.shakeTimer % 8 == 0) or (data.shakeTimer > 80 and data.shakeTimer % 32 == 0)) then
		SFX.play(74)
	end
	
	if data.shakeTimer <= 0 then
		local n = NPC.spawn(v.id+1,v.x+v.width*0.5+(v.speedX/3),v.y+(v.speedY/3),v.section,false,false)
		n.x = n.x - n.width*0.5
		n.y = n.y - n.height*0.5
		n.speedY = NPC.config[v.id].launchspeed
		n:mem(0x12E, FIELD_WORD, 2)

		local e = Effect.spawn(v.id+1,v)
		e.variant = 2
		e.rotation = {-7, 7}
		e.speedY = 3.5
		onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
		SFX.play(64)
		SFX.play(RNG.randomEntry(NPC.config[v.id].firingSFX))
	elseif data.shakeTimer == 80 then
		SFX.play(49)
	end
end

function ai.onDrawLauncher(v)
	if v.despawnTimer <= 0	--If despawned
	or v.forcedState > 0	--Various forced states
	or not v.data.initialized 
	then return end
	
	local data = v.data
	local timer = data.shakeTimer
	local range = 3
	local itensity = 2
	if data.shakeTimer >= 80 and NPC.config[v.id].timeUntilLaunch ~= 80 then 
		range = 2
		itensity = 0.5 
	end
	
	utils.drawNPC(v,{
		frame = 0,
		xOffset = math.sin(timer * itensity) * range, -- stole this from deltom lol,
		priority = -25 - 0.01
	})
	v.animationFrame = -99
end

function ai.onTickEndProjectile(v)
	--Don't act during time freeze
	if Defines.levelFreeze -- Frozen by stopwatches
	or v.despawnTimer <= 0 -- Despawned
	or v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		return
	end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	--Initialize
	if not data.initialized then
		v.isProjectile = false
		data.killCombo = 2
		data.initialized = true
	end
	
	local hitSolid = false
	local hitNPC = false

	for _,p in ipairs(Player.getIntersecting(v.x - 2, v.y - 2, v.x + v.width + 2, v.y + v.height + 2)) do
		if p.deathTimer <= 0 and v:mem(0x12E, FIELD_WORD) <= 0 then
			p:harm()
		end
	end
	
	-- Yoinked from Basegame Wario/WarioRewrite's code lol
	for _,b in Block.iterateIntersecting(v.x,v.y-2,v.x+v.width,v.y+v.height+2) do
		-- If block is visible
		if b.isHidden == false and b:mem(0x5A, FIELD_BOOL) == false and not Block.SEMISOLID_MAP[b.id] then
			-- If the block can be broken
			if Block.MEGA_SMASH_MAP[b.id] or Block.config[b.id].smashable then 
				b:remove(true)
			elseif Block.LAVA_MAP[b.id] and config.stoponsolids then
				v:kill(HARM_TYPE_LAVA)
				return
			elseif (Block.MEGA_HIT_MAP[b.id] or Block.SOLID_MAP[b.id]) then
				b:hitWithoutPlayer(false)
				hitSolid = true
			end
		end
	end
	
	for _, n in NPC.iterateIntersecting(v.x,v.y-2,v.x+v.width,v.y+v.height+2) do -- handles hitting NPCs
		if n.isValid and (not n.friendly) and n.despawnTimer > 0 and (not n.isGenerator) 
		and n.forcedState == 0 and n.heldIndex == 0 and n.id ~= v.id then
			if NPC.HITTABLE_MAP[n.id] then
				if not NPC.MULTIHIT_MAP[n.id] and not config.stoponnpcs then
					local oldScore = NPC.config[n.id].score
					NPC.config[n.id].score = data.killCombo
					n:harm(3)
					NPC.config[n.id].score = oldScore
					if data.killCombo >= 11 then data.killCombo = 9 end
					data.killCombo = math.min(data.killCombo + 1, 11)
				else
					n:harm(3)
					hitNPC = true
				end
			elseif NPC.SWITCH_MAP[n.id] then
				if coloredSwitches[n.id] then -- presses the SMBX2 lua-based switches
					smallSwitch.press(n)
				else -- presses the 1.3 switches
					n:harm(1)
				end
				hitNPC = true
			end
		end
	end
	
	if (hitSolid and (config.stoponsolids or config.stoponcontact)) 
	or (hitNPC and (config.stoponnpcs or config.stoponcontact))
	then v:kill(4) end
end

onlinePlayNPC.onlineHandlingConfig[828] = {
	getExtraData = function(v)
		local data = v.data

		return {
			isShaking = data.isShaking,
			shakeTimer = data.shakeTimer,
		}
	end,
	setExtraData = function(v,receivedData)
		local data = v.data
		data.isShaking = receivedData.isShaking
		datashakeTimer = receivedData.shakeTimer
	end,
}

onlinePlayNPC.onlineHandlingConfig[829] = {
	getExtraData = function(v)
		local data = v.data

		return {
			killCombo = data.killCombo,
		}
	end,
	setExtraData = function(v,receivedData)
		local data = v.data
		data.killCombo = receivedData.killCombo
	end,
}

return ai