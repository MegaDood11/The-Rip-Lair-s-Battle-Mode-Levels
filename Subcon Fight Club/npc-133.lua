local bullet = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

function bullet.onTickNPC(v)
	v.friendly = false
end

function bullet.onInitAPI()
	npcManager.registerEvent(npcID, bullet, "onTickNPC")
end

return bullet