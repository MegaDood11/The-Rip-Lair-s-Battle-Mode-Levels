local barrel = {}

local npcManager = require("npcManager")
local barrelAI = require("AI/launchBarrel")

local npcID = NPC_ID

barrelAI.registerBarrel(npcID, "auto", {delay = 25})

return barrel