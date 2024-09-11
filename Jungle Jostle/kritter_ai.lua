--[[

	Written by MrDoubleA
    Please give credit!
    
    Graphics made by and made at the request of FireSeraphim

	Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local onlinePlayNPC = require("scripts/onlinePlay_npc")

local effectconfig = require("game/effectconfig")


local kritter = {}


kritter.idList = {}
kritter.typeMap = {}

kritter.TYPE_WALKER   = 0 -- Walks straight foward.
kritter.TYPE_BOUNCER  = 1 -- Bounces a few times, before doing a larger jump.
kritter.TYPE_JUMPER   = 2 -- Jumps back and forth in a fixed arc.
kritter.TYPE_MIMICKER = 3 -- Jumps whenever the player does.

local STATE_NORMAL = 0
local STATE_JUMP   = 1
local STATE_FALL   = 2

local function getAnimationFrame(v) -- Function to get the NPC's current frame
    local config = NPC.config[v.id]
    local data = v.data

    local f = 0

    if data.state == STATE_NORMAL then
        f = (math.floor(data.animationTimer/config.framespeed)%(config.frames*0.625))
    elseif data.state == STATE_JUMP then
        f = math.min((config.frames*0.1875)-1,math.floor(data.animationTimer/config.framespeed))+(config.frames*0.625)
    elseif data.state == STATE_FALL then
        f = math.min((config.frames*0.1875)-1,math.floor(data.animationTimer/config.framespeed))+(config.frames*0.8125)
    end

    return npcutils.getFrameByFramestyle(v,{frame = f})
end

function effectconfig.onTick.TICK_KRITTER(v) -- Logic for kritter death effects
    if v.timer == v.lifetime-1 then
        v.speedX = math.abs(v.speedX)*v.direction
    end

    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end

function kritter.register(id,type)
    npcManager.registerEvent(id,kritter,"onTickEndNPC")

    table.insert(kritter.idList,id)
    kritter.typeMap[id] = type
end

function kritter.onInitAPI()
    registerEvent(kritter,"onPostNPCHarm")
end

function kritter.onPostNPCHarm(v,reason,culrpit)
    if not kritter.typeMap[v.id] or reason == HARM_TYPE_OFFSCREEN then return end

    local config = NPC.config[v.id]
    local data = v.data

    if config.harmSFX then
        SFX.play(config.harmSFX)
    end
end

function kritter.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
    local config = NPC.config[v.id]
    local data = v.data
	
	if v.despawnTimer <= 0 then
		data.state = nil
		return
	end

	if not data.state then
        data.state = STATE_NORMAL

        data.bounces = 0 -- Used by bouncers
        
        data.animationTimer = 0
    end
    
    data.animationTimer = data.animationTimer + 1

	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
    then
        data.state = STATE_NORMAL
        data.bounces = 0

        v.animationFrame = getAnimationFrame(v)

        return
    end

    if data.state == STATE_NORMAL then
        if kritter.typeMap[v.id] == kritter.TYPE_WALKER then
            v.speedX = 1.5*v.direction
        elseif kritter.typeMap[v.id] == kritter.TYPE_BOUNCER then
            v.speedX = 1.5*v.direction

            if v.collidesBlockBottom then
                data.bounces = data.bounces + 1

                if data.bounces > config.bounces then
                    v.speedY = config.jumpYSpeed
                    data.bounces = 0
                else
                    v.speedY = config.bounceYSpeed
                end

                data.state = STATE_JUMP
                data.animationTimer = 0
            end
        elseif kritter.typeMap[v.id] == kritter.TYPE_JUMPER then
            if v.collidesBlockBottom then
                data.state = STATE_JUMP
                data.animationTimer = 0
                
                v.speedX = config.jumpXSpeed*v.direction
                v.speedY = config.jumpYSpeed
            end
        elseif kritter.typeMap[v.id] == kritter.TYPE_MIMICKER then
            v.speedX = 1.5*v.direction

            if v.collidesBlockBottom then
                local jump = false

                for _,w in ipairs(Player.get()) do
                    if w.forcedState == 0 and w.deathTimer == 0 and not w:mem(0x13C,FIELD_BOOL) and w:mem(0x11C,FIELD_WORD) > 0 then -- If this player is jumping
                        jump = true
                        break
                    end
                end

                if jump then
                    data.state = STATE_JUMP
                    data.animationTimer = 0

                    v.speedY = config.jumpYSpeed
                end
            end
        end
    elseif data.state == STATE_JUMP or data.state == STATE_FALL then
        if v.collidesBlockBottom then -- Return to normal if on ground
            data.state = STATE_NORMAL
            data.animationTimer = 0

            if kritter.typeMap[v.id] == kritter.TYPE_JUMPER then -- Change direction if a jumper
                v.speedX = -v.speedX
            end
        elseif data.state == STATE_JUMP and v.speedY > 0 then -- Start falling animation if falling
            data.state = STATE_FALL
            data.animationTimer = 0
        end
    end
    
    v.animationFrame = getAnimationFrame(v)
end

local npcList = {752, 753, 754, 755}

onlinePlayNPC.onlineHandlingConfig[#npcList] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			state = data.state,
			animationTimer = data.animationTimer,
			bounces = data.bounces,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.state = receivedData.state
		data.animationTimer = receivedData.animationTimer
		data.bounces = receivedData.bounces
	end,
}

return kritter