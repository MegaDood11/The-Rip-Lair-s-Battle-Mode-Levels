local onlinePlay = require("scripts/onlinePlay")

local battleGeneral = require("scripts/battleGeneral")

battleTimer = require("scripts/battleTimer")

local thing1 = onlinePlay.createVariable("thing1","uint16",true,0)
local thing2 = onlinePlay.createVariable("thing2","uint16",true,0)

function onTick()
	if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.optionTimeValues[battleOptions.getModeRuleset().timeLimit] - 100 and thing1.value == 0 then
		triggerEvent("poisonDescend1")
		thing1.value = 1
	end
	if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.optionTimeValues[battleOptions.getModeRuleset().timeLimit] - 200 and thing2.value == 0 then
		triggerEvent("poisonDescend2")
		thing2.value = 1
	end
end

function onEvent(e)
	if e == "poisonDescend1" or e == "poisonDescend2" then
		SFX.play(42)
	end
end

function onDraw()
	-- Text.print(battleTimer.secondsLeft, 10, (camera.height - 26))
end