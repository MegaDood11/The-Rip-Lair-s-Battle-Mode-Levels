--------------------------------------------------
-- Level code
-- Created 21:36 2025-8-4
--------------------------------------------------

local smithers = {}

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local smithersevent = onlinePlay.createVariable("smithersevent","uint16",true,0)
local smithersspawn = onlinePlay.createVariable("smithersspawn","uint16",true,0)

local smithersback = {}

local smithersdied = false

-- Run code on level start
function onStart()
    smithers = Layer.get("smithers")
	
	smithersback = player.sectionObj.background:get("krusty")
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    if battleTimer.isActive and battleTimer.secondsLeft <= 90 and smithersevent.value == 0 then
		
	end
	if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.optionTimeValues[battleOptions.getModeRuleset().timeLimit] - 210 and smithersspawn.value == 0 then
		smithersspawn.value = 1
		SFX.play("smithers.mp3")
		smithers:show(false)
		smithersback.opacity = 0
		Audio.MusicChange(player.section, "Downtown Springfield/Smithers.ogg", 1)
	end
	if battleTimer.isActive and battleTimer.secondsLeft <= 0 and smithersdied == false then
		for k,v in ipairs(NPC.get(610)) do
			smithersdied = true
			v:kill(HARM_TYPE_PROJECTILE_USED)
		end
	end
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

