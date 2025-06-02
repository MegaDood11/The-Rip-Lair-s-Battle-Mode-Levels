--------------------------------------------------
-- Level code
-- Created 20:57 2025-5-22
--------------------------------------------------

-- Run code on level start
function onStart()
    SFX.play("audience.mp3", 0.4, 0)
end

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local thing1 = onlinePlay.createVariable("thing1","uint16",true,0)
local thing2 = onlinePlay.createVariable("thing2","uint16",true,0)

function onTick()
	if battleTimer and battleTimer.secondsLeft == battleTimer.optionTimeValues[battleOptions.getModeRuleset().timeLimit] - 90 and thing1.value == 0 then
		triggerEvent("bowserbootup")
		thing1.value = 1
	end
	if battleTimer and battleTimer.secondsLeft == 60 and thing2.value == 0 then
		triggerEvent("bowserbootup2")
		thing2.value = 1
	end
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    if eventName == "bowserbootup" or eventName == "bowserbootup2" then
		SFX.play("bowserbootup.mp3")
	end
end

