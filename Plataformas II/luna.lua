local onlinePlay = require("scripts/onlinePlay")

local layer1MoveTime = 256
local layer1MoveDistance = 192
local layer2MoveTime = 192
local layer2MoveDistance = 288

local layer1MoveTimer = onlinePlay.createVariable("layer1MoveTimer","uint16",true,0)
local layer2MoveTimer = onlinePlay.createVariable("layer2MoveTimer","uint16",true,0)
local layer3MoveTimer = onlinePlay.createVariable("layer3MoveTimer","uint16",true,0)
local layer4MoveTimer = onlinePlay.createVariable("layer4MoveTimer","uint16",true,0)
local layer1
local layer2
local layer3
local layer4

function onStart()
    layer1 = Layer.get("1")
	layer2 = Layer.get("2")
	layer3 = Layer.get("3")
	layer4 = Layer.get("4")
end

function onTick()
    if layer1 ~= nil then
        layer1.pauseDuringEffect = false

        if not layer1:isPaused() then
            local time = layer1MoveTime/math.pi/2

            layer1.speedX = -math.sin(layer1MoveTimer.value/time)*layer1MoveDistance/time*1
            layer1.pauseDuringEffect = false
            
            layer1MoveTimer.value = (layer1MoveTimer.value + 1) % layer1MoveTime
        end
    end
	if layer2 ~= nil then
        layer2.pauseDuringEffect = false

        if not layer2:isPaused() then
            local time = layer1MoveTime/math.pi/2

            layer2.speedX = -math.sin(layer2MoveTimer.value/time)*layer1MoveDistance/time*0.5
            layer2.pauseDuringEffect = false
            
            layer2MoveTimer.value = (layer2MoveTimer.value + 1) % layer1MoveTime
        end
    end
	
	if layer3 ~= nil then
        layer3.pauseDuringEffect = false

        if not layer3:isPaused() then
            local time = layer1MoveTime/math.pi/2

            layer3.speedX = math.sin(layer1MoveTimer.value/time)*layer1MoveDistance/time*1
            layer3.pauseDuringEffect = false
            
            layer3MoveTimer.value = (layer3MoveTimer.value + 1) % layer1MoveTime
        end
    end
	
	if layer4 ~= nil then
        layer4.pauseDuringEffect = false

        if not layer4:isPaused() then
            local time = layer2MoveTime/math.pi/2

            layer4.speedY = -math.sin(layer3MoveTimer.value/time)*layer2MoveDistance/time*0.5
            layer4.pauseDuringEffect = false
            
            layer3MoveTimer.value = (layer3MoveTimer.value + 1) % layer2MoveTime
        end
    end
	
end