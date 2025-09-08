--------------------------------------------------
-- Level code
-- Created 12:49 2025-7-26
--------------------------------------------------

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local neutralweather = onlinePlay.createVariable("neutralweather","uint16",true,0)
local stormweather = onlinePlay.createVariable("stormweather","uint16",true,0)
local thunder = onlinePlay.createVariable("thunder","uint16",true,0)
local raining = onlinePlay.createVariable("raining","uint16",true,0)

local easyliquids = require("easyliquids")

local back = {}
local stormback = {}
local sky = {}
local stormsky = {}
local mountains = {}
local stormmountains = {}

local backopacity = 1
local stormbackopacity = 0
local skyopacity = 1
local stormskyopacity = 0
local mountainsopacity = 1
local stormmountainsopacity = 0

--local sec = Section(0)
--sec.settings:effects.weather = 1

easyliquids.levelLiquids = {
    [0] = {
        liquidtype = easyliquids.TYPE_WATER,
        height = 32,
        targetheight = 64,
        goback = true,
        waittime = 1,
		movetime = 5,
		easing = easyliquids.EASING_INOUTSINE
    }
}

-- Run code on level start
function onStart()
    back = player.sectionObj.background:get("back")
	
	stormback = player.sectionObj.background:get("stormback")
	
	sky = player.sectionObj.background:get("sky")
	
	stormsky = player.sectionObj.background:get("stormsky")
	
	mountains = player.sectionObj.background:get("mountains")
	
	stormmountains = player.sectionObj.background:get("stormmountains")
	
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    back.opacity = backopacity
	stormback.opacity = stormbackopacity
	sky.opacity = skyopacity
	stormsky.opacity = stormskyopacity
	mountains.opacity = mountainsopacity
	stormmountains.opacity = stormmountainsopacity
	
	
	
	--Storm
	if battleTimer.isActive and battleTimer.secondsLeft <= 150 and stormweather.value == 0 then
		backopacity = backopacity - 0.001
		stormbackopacity = stormbackopacity + 0.001
		skyopacity = skyopacity - 0.001
		stormskyopacity = stormskyopacity + 0.001
		mountainsopacity = mountainsopacity - 0.001
		stormmountainsopacity = stormmountainsopacity + 0.001
	end
	if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.optionTimeValues[battleOptions.getModeRuleset().timeLimit] - 150 and thunder.value == 0 then
		thunder.value = 1
		SFX.play("luigireference.mp3")
	end
	if battleTimer.isActive and battleTimer.secondsLeft <= 140 then
		player.sectionObj.effects.weather = WEATHER_RAIN
		player.sectionObj.effects.screenEffect = NIL
	end
	if battleTimer.isActive and battleTimer.secondsLeft <= 140 and raining.value == 0 then
		raining.value = 1
		SFX.play("rain.mp3")
	end
	if backopacity <= 0 then
		stormweather.value = 1
	end
	
	
	
	--Clear
	if battleTimer.isActive and battleTimer.secondsLeft <= 15 then
		backopacity = backopacity + 0.001
		stormbackopacity = stormbackopacity - 0.001
		skyopacity = skyopacity + 0.001
		stormskyopacity = stormskyopacity - 0.001
		mountainsopacity = mountainsopacity + 0.001
		stormmountainsopacity = stormmountainsopacity - 0.001
	end
	if battleTimer.isActive and battleTimer.secondsLeft <= 7 then
		player.sectionObj.effects.weather = NIL
		player.sectionObj.effects.screenEffect = NIL
	end
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end