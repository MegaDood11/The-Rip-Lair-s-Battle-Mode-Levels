local bones = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

function bones.onTickNPC(v)
	v.despawnTimer = 180
end

function bones.onInitAPI()
	npcManager.registerEvent(npcID, bones, "onTickNPC")
end

return bones