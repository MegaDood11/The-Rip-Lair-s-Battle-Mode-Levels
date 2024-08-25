local onlinePlay = require("scripts/onlinePlay")

local crusherMoveTime = 1200
local crusherMoveDistance = 416

local crusherMoveTimer = onlinePlay.createVariable("crusherMoveTimer","uint16",true,0)
local crusherLayer

function onStart()
    crusherLayer = Layer.get("Crusher")
end

function onTick()
    if crusherLayer ~= nil then
        crusherLayer.pauseDuringEffect = false

        if not crusherLayer:isPaused() then
            local time = crusherMoveTime/math.pi/2

            crusherLayer.speedY = math.sin(crusherMoveTimer.value/time)*crusherMoveDistance/time*0.5
            crusherLayer.pauseDuringEffect = false
            
            crusherMoveTimer.value = (crusherMoveTimer.value + 1) % crusherMoveTime
        end
    end
end

local blockRespawning = require("scripts/blockRespawning")

blockRespawning.defaultRespawnTime = 32*32