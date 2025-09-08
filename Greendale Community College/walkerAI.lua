local walker = {}

local walkerFrameHelper = {}
local npcManager = require("npcmanager")

walker.state = {
    IDLE = 1,
    WALK = 2,
    TALK = 3
}

-- FrameConfig should look something like this:
--[[
{
    count={1,1,2},
    speed={8,8,8},
    offset={
        [-1]={0,0,1},
        [1]={2,2,3}
    },
}
]]
function walker.register(id, frameConfig)
    walkerFrameHelper[id] = frameConfig
    npcManager.registerEvent(id, walker, "onTickNPC")
    npcManager.registerEvent(id, walker, "onDrawNPC")
end

function walker.onMessageBox(eventObj, message, plyr, npc)
	if(eventObj.cancelled) then return end
	--[[
	local npc = nil;
	if(player.upKeyPressing) then
		npc = a2xt_message.getTalkNPC();
	end
    ]]
    
    if npc and npc.data.isWalker then
        walker.setWalkerState(npc, walker.state.TALK)
        npc.data.isVanillaPaused = true
    end
end

registerEvent(walker, "onMessageBox")

function walker.setWalkerState(npc, state)
	npc.data.state = state
	npc.data.timer = 0
end

function walker.onTickNPC(v)
    local data = v.data
    if data.timer == nil or v.despawnTimer <= 0 then
        data.timer = 0
        data.state = 1
        return
    end

    if data.anchor == nil then
        data.anchor = v.x
        data.isWalker = true
    end
    
    if data.state < 3 then
        data.timer = data.timer + 1
    end

    if v.dontMove then return end

    if data.state == 1 then
        if data.timer > 75 then
            walker.setWalkerState(v, RNG.randomInt(1,2))
            v.direction = RNG.randomInt(0,1) * 2 - 1

            if data.state == 2 and math.abs(v.x - data.anchor) > 150 then
                v.direction = math.sign(data.anchor - v.x)
            end
        end
        v.speedX = 0
    elseif data.state == 2 then
        v.speedX = 0.5 * v.direction
        if data.timer > 48 then
            walker.setWalkerState(v, RNG.randomInt(1,2))
            if data.state == 2 and math.abs(v.x - data.anchor) > 150 then
                v.direction = math.sign(data.anchor - v.x)
            end
        end
    else
        v.speedX = 0
        if v.data.isVanillaPaused then
            if not Misc.isPaused() then
                walker.setWalkerState(v, walker.state.IDLE)
                v.data.isVanillaPaused = false
            end
        end
    end
end

function walker.onDrawNPC(v)
    if v.despawnTimer <= 0 then return end
    local data = v.data
    if data.timer == nil then
        data.timer = 0
        data.state = 1
        return
    end

    if v.dontMove then v.direction = v:mem(0xD8, FIELD_FLOAT) end
    
    if data.state == 3 then
        data.timer = data.timer + 1
    end

    v.animationTimer = 500

    local f = math.floor(data.timer/walkerFrameHelper[v.id].speed[data.state]) % walkerFrameHelper[v.id].count[data.state]

    v.animationFrame = f + walkerFrameHelper[v.id].offset[v.direction][data.state]
end

return walker