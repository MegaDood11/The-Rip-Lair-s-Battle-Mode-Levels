local battleGeneral = require("scripts/battleGeneral")
local battleHUD = require("scripts/battleHUD")
local battleTimer = require("scripts/battleTimer")
local battleOptions = require("scripts/battleOptions")

local battleBubbleBlaster = require("battleBubbleBlaster")
local battleStars = require("scripts/battleStars")

local spout = require("spout")

spout.whitelistNPC({754})

function battleTimer.onStart()
    battleTimer.set(60)

    battleStars.spawnTimeMin = lunatime.toTicks(2)
    battleStars.spawnTimeMax = lunatime.toTicks(5)
    battleStars.spawnTimeStart = lunatime.toTicks(4)
end