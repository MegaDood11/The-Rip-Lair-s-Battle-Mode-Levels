local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")
battleTimer = require("scripts/battleTimer")

local hurryUp = onlinePlay.createVariable("hurryUp","boolean",true,false)
local hurryTimer = onlinePlay.createVariable("hurryTimer","uint16",true,0)

function onTick()
    if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.hurryTime then
		triggerEvent("mario pissing")
		if hurryUp.value == false then
			hurryUp.value = true
			hurryTimer.value = 1
			Audio.MusicChange(0, 0)
			SFX.play("hurryUp.ogg")
		end
    end
	
	if hurryTimer.value > 0 then
		hurryTimer.value = hurryTimer.value + 1
		if hurryTimer.value == 188 then
			Audio.MusicChange(0, "SMB World 1/Super Mario Bros. (1985-09-13)(Nintendo EAD)(Nintendo).nsf|0;g=2;e0")
			Audio.MusicSetTempo(1.4)
		end
	end
end