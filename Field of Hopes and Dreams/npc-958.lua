local npcManager = require("npcManager")

local bluePhanto = require("scripts/npc/bluePhanto")


local npcID = NPC_ID
local phanto = {}

local phantoSettings = table.join({
	id = npcID,
},bluePhanto.sharedSettings)

npcManager.setNpcSettings(phantoSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_TAIL, HARM_TYPE_SWORD})

bluePhanto.register(npcID)

return phanto