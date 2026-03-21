local blockRespawning = require("scripts/blockRespawning")

blockRespawning.defaultRespawnTime = 32*32
local blockyGlobe = require("blockyGlobe")
local extraBGOProperties = require("extraBGOProperties")
local bouncyPits = require("bouncyPits")
local bouncyLava = require("bouncyLava")
function onStart()
    -- change the zone block id & spawn one in the first pit with 100 strength
    -- bouncyPits.zoneBlockID = 25
    -- Block.config[25].passthrough = true
    -- local b = Block.spawn(25, -199744, -200000)
    -- b.width, b.height = 96, 128
    -- b.data._settings.strength = 100
end






