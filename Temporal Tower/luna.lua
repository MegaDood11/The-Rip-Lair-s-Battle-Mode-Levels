local battleGeneral = require("scripts/battleGeneral")
local battleHUD = require("scripts/battleHUD")
local battleTimer = require("scripts/battleTimer")

battleHUD.starNeutralColor = Color(0.25,1,1)

function battleGeneral.musicShouldBeSpedUp()
	if battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode] ~= nil and battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode]() then
        Audio.MusicChange(0, "Temporal Tower/Dialga's Fight to the Finish! (PMD2 Remastered Project).ogg")
    end

    if battleTimer.isActive and battleTimer.secondsLeft <= battleTimer.hurryTime then
        Audio.MusicChange(0, "Temporal Tower/Dialga's Fight to the Finish! (PMD2 Remastered Project).ogg")
    end
    
    return false
end