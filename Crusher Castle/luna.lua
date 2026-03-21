local onlinePlay = require("scripts/onlinePlay")

local crusherMoveTime = 1200
local crusherMoveDistance = 416

local crusherMoveTimer = onlinePlay.createVariable("crusherMoveTimer","uint16",true,0)
local crusherPauseTimer = onlinePlay.createVariable("crusherPauseTimer","uint16",true,0)
local crusherLayer

function onStart()
    crusherLayer = Layer.get("Crusher")
end

function onPostBlockHit(v, fromUpper)
	if v.id == 832 then
		if crusherPauseTimer.value == 0 then
			crusherPauseTimer.value = 192
			v.data.set = 1
			SFX.play(30)
		else
			crusherPauseTimer.value = 0
		end
	end
end

function onTick()
    if crusherLayer ~= nil then
        crusherLayer.pauseDuringEffect = false

        if not crusherLayer:isPaused() then
            local time = crusherMoveTime/math.pi/2

            crusherLayer.speedY = math.sin(crusherMoveTimer.value/time)*crusherMoveDistance/time*0.5
            crusherLayer.pauseDuringEffect = false
            
			if crusherPauseTimer.value > 0 then
				crusherPauseTimer.value = crusherPauseTimer.value - 1
				crusherLayer.speedY = 0
				for _,v in ipairs(Block.get(832)) do
					if v.data.set == 0 then v.data.set = 1 end
					if crusherPauseTimer.value % 64 == 0 then
						v.data.set = v.data.set + 1
						SFX.play(26)
					end
				end
				return
			end
			
			for _,v in ipairs(Block.get(832)) do
				v.data.set = 0
			end
			
            crusherMoveTimer.value = (crusherMoveTimer.value + 1) % crusherMoveTime
        end
    end
end

local blockRespawning = require("scripts/blockRespawning")

blockRespawning.defaultRespawnTime = 32*32