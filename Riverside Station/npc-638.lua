local npcManager = require("npcManager")
local spawner = require("npcs/ai/spawner")
local npcutils = require("npcs/npcutils")

local billSpawner = {}

local npcID = NPC_ID

local fields = {
    "sound", "npc", "speed", "delay", "enabled", "homing", "side"
}

local cams = {
    {enabled = false, timer = 0, spawncounter=0},
    {enabled = false, timer = 0, spawncounter=0}
}

local function onSpawnerTriggered(cam, settings, npcRef)
    for k,v in ipairs(fields) do
        cams[cam.idx][v] = settings[v]
    end
    cams[cam.idx].timer = 0
    cams[cam.idx].spawncounter = 0
    cams[cam.idx].direction = 0
end

spawner.register(npcID, onSpawnerTriggered)

function billSpawner.onInitAPI()
    registerEvent(billSpawner, "onTickEnd")
end

function billSpawner.onTickEnd()
    if Defines.levelFreeze then return end

    for k,v in ipairs(Camera.get()) do
        local c = cams[v.idx]
        if c.enabled then
            c.timer = c.timer + 1
            if c.timer % c.delay == 0 then

                local y = v.y + RNG.random(100, v.height - 100)
                local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
                if c.homing then
                    y = RNG.random(p.y - 10, p.y + p.height + 10)
                end

                -- default c.side == 0, Random
                local x = RNG.irandomEntry{-1, 1}

                -- Direction setting
                if      c.side == 1  then
                    if  c.direction ~= DIR_RANDOM  then
                        x = c.direction
                    end
                
                -- Alternating
                elseif  c.side == 2  then
                    if  c.startside == nil  then
                        c.startside = c.direction
                        if  c.direction == DIR_RANDOM  then
                            c.startside = x
                        end
                        -- convert from sign to 0 or 1
                        c.startside = 0.5*(c.startside + 1)
                    end
                    x = 2*((c.spawncounter + c.startside) % 2) - 1
                
                -- Opposite/Same from player
                elseif  c.side == 3  or  c.side == 4  then
                    x = -1
                    local pMidX = p.x + 0.5*p.width 
                    local cMidX = v.x + 0.5*v.width
                    if  (pMidX < cMidX  and  c.side == 3)  or  (pMidX > cMidX  and  c.side == 4)  then
                        x = 1
                    end
                end

                local n = NPC.spawn(c.npc, v.x + 0.5 * v.width + x * 0.5 * v.width, y, p.section, false, true)
                n.x = n.x + x * 0.5 * n.width
                n.layerName = "Spawned NPCs"
                n.direction = -x
                n.speedX = -x * c.speed
                if c.sound > 0 then
                    SFX.play(c.sound)
                end
                c.spawncounter = c.spawncounter + 1
            end
        end
    end
end

return billSpawner;