local onlinePlay = require("scripts/onlinePlay")

local battleGeneral = require("scripts/battleGeneral")

battleTimer = require("scripts/battleTimer")

function onTick()
	if battleTimer.secondsLeft == 200 then
		triggerEvent("poisonDescend1")
	end
	if battleTimer.secondsLeft == 100 then
		triggerEvent("poisonDescend2")
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