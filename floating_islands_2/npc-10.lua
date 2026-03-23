local coin = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

function coin.onTickEndNPC(v)
	v.animationFrame = math.floor(lunatime.tick() / 6) % 8
end

function coin.onInitAPI()
	npcManager.registerEvent(npcID, coin, "onTickEndNPC")
end

return coin