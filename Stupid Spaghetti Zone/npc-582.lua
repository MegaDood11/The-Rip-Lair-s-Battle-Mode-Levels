local bumper = {}
local lineguide = require("lineguide")
local npcManager = require("npcManager")

local npcID = NPC_ID

lineguide.registerNpcs(npcID)

lineguide.properties[npcID] = {lineSpeed = 2}

return bumper