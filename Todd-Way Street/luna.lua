
local battleGeneral = require("scripts/battleGeneral")
local battleTimer = require("scripts/battleTimer")
local blockRespawning = require("scripts/blockRespawning")
blockRespawning.defaultRespawnTime = 64*25


function battleGeneral.musicShouldBeSpedUp()
    if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.hurryTime then --battleTimer.hurryTime
        Audio.MusicChange(0, "Todd-Way Street/TORNADO-PINCH.ogg")
    end
    return false
end

local guests = {
	[1] = "Chicken-Alfredo", -- Alfred Chicken (Requested by Deltom/Sara)
	[2] = "Samuel-And-Maximus", -- Sam & Max
	[3] = "Loop-The-Three", -- Lupin The 3rd
	[4] = "Sleepyhead", -- Sleepy Dee (Requested by Sleepy)
}

-- Run code on level start
function onStart()
    --Your code here
	for i = 1,#guests,1 do
		if RNG.randomInt(1,10) == 1 then
			local guest = Layer.get(guests[i])
			guest:show()
		end
	end
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
	
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

--[[
function onDraw()
	if lunatime.tick() > 65 * 17.75 then return end
	Graphics.drawScreen{
		color = Color.black .. 1,
		priority = 10
	}
end
--]]