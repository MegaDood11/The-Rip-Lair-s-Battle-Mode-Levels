local battleGeneral = require("scripts/battleGeneral")

battleTimer = require("scripts/battleTimer")

function onTick()
    if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.hurryTime then --battleTimer.hurryTime
		triggerEvent("mario pissing")
    end
end