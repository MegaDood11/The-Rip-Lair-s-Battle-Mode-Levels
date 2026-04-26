local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")
local battleTimer = require("scripts/battleTimer")

function battleGeneral.musicShouldBeSpedUp()
	if battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode] ~= nil and battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode]() then
        Audio.MusicChange(0, "Firework Rally/Mushroom City Final Lap.ogg")
    end

    if battleTimer.isActive and battleTimer.secondsLeft <= battleTimer.hurryTime then
        Audio.MusicChange(0, "Firework Rally/Mushroom City Final Lap.ogg")
    end
    
    return false
end