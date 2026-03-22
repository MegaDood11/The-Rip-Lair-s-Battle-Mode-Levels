local onlinePlay = require("scripts/onlinePlay")
local battleGeneral = require("scripts/battleGeneral")

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

local layer5MoveTime = 256
local layer5MoveDistance = 192
local layer6MoveTime = 192
local layer6MoveDistance = 288

local layer5MoveTimer = onlinePlay.createVariable("layer5MoveTimer","uint16",true,0)
local layer6MoveTimer = onlinePlay.createVariable("layer6MoveTimer","uint16",true,0)
local layer7MoveTimer = onlinePlay.createVariable("layer7MoveTimer","uint16",true,0)
local layer8MoveTimer = onlinePlay.createVariable("layer8MoveTimer","uint16",true,0)
local layer5
local layer6
local layer7
local layer8

function onStart()
    layer1 = Layer.get("sinea0f7.4x0y-5d7.4")
	layer2 = Layer.get("sinea0f8.7x8y0d8.7")
	layer3 = Layer.get("sinea0f8.7x-8y0d8.7")
	layer4 = Layer.get("sinea0f9.4x0y-7d9.4")
	layer5 = Layer.get("1")
	layer6 = Layer.get("2")
	layer7 = Layer.get("3")
	layer8 = Layer.get("4")
end

function onTick()
	
	if battleGeneral.mode == battleGeneral.gameMode.BOMBS then
		Layer.get("sinea0f7.4x0y-5d7.4"):hide(true)
		Layer.get("sinea0f8.7x8y0d8.7"):hide(true)
		Layer.get("sinea0f8.7x-8y0d8.7"):hide(true)
		Layer.get("sinea0f9.4x0y-7d9.4"):hide(true)
	else
		Layer.get("1"):hide(true)
		Layer.get("2"):hide(true)
		Layer.get("3"):hide(true)
		Layer.get("4"):hide(true)
	end

    if layer1 ~= nil then
        layer1.pauseDuringEffect = false

        if not layer1:isPaused() then
            local time = layer1MoveTime/math.pi/2

            layer1.speedY = -math.sin(layer1MoveTimer.value/time)*layer1MoveDistance/time*0.5
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

            layer3.speedX = math.sin(layer2MoveTimer.value/time)*layer1MoveDistance/time*0.5
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
	
	if layer5 ~= nil then
        layer5.pauseDuringEffect = false

        if not layer5:isPaused() then
            local time = layer1MoveTime/math.pi/2

            layer5.speedX = -math.sin(layer5MoveTimer.value/time)*layer5MoveDistance/time*1
            layer5.pauseDuringEffect = false
            
            layer5MoveTimer.value = (layer5MoveTimer.value + 1) % layer5MoveTime
        end
    end
	if layer6 ~= nil then
        layer6.pauseDuringEffect = false

        if not layer6:isPaused() then
            local time = layer5MoveTime/math.pi/2

            layer6.speedX = -math.sin(layer6MoveTimer.value/time)*layer5MoveDistance/time*0.5
            layer6.pauseDuringEffect = false
            
            layer6MoveTimer.value = (layer6MoveTimer.value + 1) % layer5MoveTime
        end
    end
	
	if layer7 ~= nil then
        layer7.pauseDuringEffect = false

        if not layer7:isPaused() then
            local time = layer5MoveTime/math.pi/2

            layer7.speedX = math.sin(layer5MoveTimer.value/time)*layer5MoveDistance/time*1
            layer7.pauseDuringEffect = false
            
            layer7MoveTimer.value = (layer7MoveTimer.value + 1) % layer5MoveTime
        end
    end
	
	if layer8 ~= nil then
        layer8.pauseDuringEffect = false

        if not layer8:isPaused() then
            local time = layer6MoveTime/math.pi/2

            layer8.speedY = -math.sin(layer7MoveTimer.value/time)*layer6MoveDistance/time*0.5
            layer8.pauseDuringEffect = false
            
            layer7MoveTimer.value = (layer7MoveTimer.value + 1) % layer6MoveTime
        end
    end
	
end