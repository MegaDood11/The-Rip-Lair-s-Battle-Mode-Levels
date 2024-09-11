local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local npcutils = require("npcs/npcutils")
local colliders = require("Colliders")

--Death effect logic and player jump mimicking taken from MrDoubleA's kritter NPCs.
--8luestorm helped with the charge hitbox

--******************************************************
--Graphics made by, and requested by FireSeraphim.
--******************************************************

local klaptraps = {}
local npcIDs = {}

local idle = Misc.resolveSoundFile("Klaptrap")
local death = Misc.resolveSoundFile("Klaptrap_die")
local playSound = false
local idleSoundObj

local STATE_NORMAL = 0
local STATE_READY  = 1
local STATE_CHARGE   = 2

--Register events
function klaptraps.register(id)
	npcManager.registerEvent(id, klaptraps, "onTickNPC")
	npcManager.registerEvent(id, klaptraps, "onTickEndNPC")
	npcIDs[id] = true
end

function klaptraps.onInitAPI()
    registerEvent(klaptraps, "onPostNPCHarm")
	registerEvent(klaptraps,"onTick")
end

function effectconfig.onTick.TICK_KLAPTRAP(v)
    if v.timer == v.lifetime-1 then
        v.speedX = math.abs(v.speedX)*v.direction
    end

    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end

function klaptraps.onPostNPCHarm(v, reason, culprit)
	--Only play if the NPC is killed but not by offscreen or if another NPC dies.
	if not npcIDs[v.id] or reason == HARM_TYPE_OFFSCREEN then return end

	SFX.play(death)

end

function klaptraps.onTick()
    if playSound then
        -- Create the looping sound effect for all of the NPC's
        if idleSoundObj == nil then
            idleSoundObj = SFX.play{sound = idle,loops = 0}
        end
    elseif idleSoundObj ~= nil then -- If the sound is still playing but there's no NPC's, stop it
        idleSoundObj:stop()
        idleSoundObj = nil
    end
    
    -- Clear playSound for the next tick
    playSound = false
end

function klaptraps.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	data.chargeTimer = data.chargeTimer or 0
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_NORMAL
		data.chargeTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.hitbox = colliders.Box(v.x, v.y, 448, v.height)
		data.deathbox = colliders.Box(v.x, v.y, 32, v.height - v.height / 4)
		data.state = STATE_NORMAL
	end
	
	if v.direction == DIR_RIGHT then
	data.hitbox.x = v.x - 32 + (32)
	if v.id == 812 then
		data.deathbox.x = v.x - 32 + (64)
	end
	else
	data.hitbox.x = v.x - 420 + (32)
	if v.id == 812 then
		data.deathbox.x = v.x - 68 + (64)
	end
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	if v.id == 812 then
		for _,plr in ipairs(Player.get()) do
			if colliders.collide(plr, data.deathbox) then
				if plr:mem(0x140,FIELD_WORD) == 0 --[[changing powerup state]] and plr.deathTimer == 0 --[[already dead]] and not Defines.cheat_donthurtme then
					plr:kill()
				end
			end
		end
	end

	if data.state == STATE_NORMAL then
		v.speedX = 1.21 * v.direction
		local myplayer=Player.getNearest(v.x,v.y)
		
		if v.id == 809 then
			data.cliffturn = true
		elseif v.id == 810 or v.id == 812 then
			data.cliffturn = false
		end
		
		if v.animationFrame == 1 or v.animationFrame == 17 then
			playSound = true
		end
		
		if v.id == 811 then
			if v.collidesBlockBottom then
				local jump = false

				for _,w in ipairs(Player.get()) do
					if w.forcedState == 0 and w.deathTimer == 0 and not w:mem(0x13C,FIELD_BOOL) and w:mem(0x11C,FIELD_WORD) > 0 then -- If this player is jumping
						jump = true
						break
					end
				end

				if jump then
					v.speedY = -8
				end
			end
		end
	end
	
	if data.state == STATE_READY then
	data.chargeTimer = data.chargeTimer + 1
	playSound = true
	v.speedX = 0
		if data.chargeTimer == 51 then
			data.state = STATE_CHARGE
		end
	end
		
	if data.state == STATE_CHARGE then
		data.chargeTimer = data.chargeTimer + 1
		playSound = true
		
		if v.id == 809 then
			data.cliffturn = false
		elseif v.id == 810 or v.id == 812 then
			data.cliffturn = true
		end
		
		v.speedX = 6 * v.direction
		if data.chargeTimer == 190 then
			data.chargeTimer = 0
			data.state = STATE_NORMAL
		end
	end
end

function klaptraps.onTickEndNPC(v)
local data = v.data

	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.hitbox = data.hitbox or colliders.Box(v.x, v.y, 320, v.height)
		data.deathbox = data.hitbox or colliders.Box(v.x, v.y, 320, v.height)
		data.state = STATE_NORMAL
	end

	data.hitbox.x = v.x
	data.hitbox.y = v.y
	if v.id == 812 then
		data.deathbox.x = v.x
		data.deathbox.y = v.y + v.height - data.deathbox.height
	end

	if v.direction == DIR_LEFT and data.state == STATE_NORMAL then
		v.animationFrame = math.floor(lunatime.tick() / 3) % 15
	elseif v.direction == DIR_RIGHT and data.state == STATE_NORMAL then
		v.animationFrame = (math.floor(lunatime.tick() / 3) % 15) + 16
	elseif v.direction == DIR_LEFT and data.state ~= STATE_NORMAL then
		v.animationFrame = math.floor(lunatime.tick() / 1) % 15
	else
		v.animationFrame = (math.floor(lunatime.tick() / 1) % 15) + 16
	end
	
	data.cliffturn = data.cliffturn or false
	
	for _,blk in ipairs(Block.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
		if blk.isHidden or blk.layerObj.isHidden or blk.layerName == "Destroyed Blocks" or blk:mem(0x5A, FIELD_WORD) == -1 then
			if data.cliffturn then
				v.direction = -v.direction
			end
		end
	end
	
    if data.cliffturn == true and v.collidesBlockBottom then
       if v.direction == DIR_RIGHT then
         if #Block.getIntersecting(v.x + 8 + 32, v.y + v.height, v.x + 8 + 32 + 5, v.y + v.height + 64) == 0 then
              v.direction = -v.direction
         end
        else
          if #Block.getIntersecting(v.x - 16 + 32, v.y + v.height, v.x - 16 + 32 + 5, v.y + v.height + 64) == 0 then
              v.direction = -v.direction
         end
       end
    end
end

return klaptraps