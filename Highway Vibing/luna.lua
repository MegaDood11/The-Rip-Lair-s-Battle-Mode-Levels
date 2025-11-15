--------------------------------------------------
-- Level code
-- Created 12:49 2025-7-26
--------------------------------------------------

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local sky = {}
local skyopacity = 1

-- Run code on level start
function onStart()
    sky = player.sectionObj.background:get("sky")
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
	skyopacity = skyopacity - 0.00005128205
	sky.opacity = skyopacity
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end