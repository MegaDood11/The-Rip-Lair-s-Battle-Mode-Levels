--------------------------------------------------
-- Level code
-- Created 0:36 2026-7-1
--------------------------------------------------

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local sunsetsky = {}
local sunsetskyopacity = 0
local sun = {}
local sunY = -144

local songchoice = 0

-- Run code on level start
function onStart()
	sunsetsky = player.sectionObj.background:get("sunsetsky")
	sun = player.sectionObj.background:get("sun")
	
	songchoice = RNG.randomInt(0, 1)
	if songchoice == 1 then
		Audio.MusicChange(0, "Delfino Burgh/delfinopier.ogg")
	end
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    sunsetskyopacity = sunsetskyopacity + 0.00004628205 --0.00005128205
	sunsetsky.opacity = sunsetskyopacity
	sunY = sunY + 0.0088 --0.00004128205
	sun.y = sunY
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

