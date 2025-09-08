local npcManager = require("npcManager")
local npc = {}
local id = NPC_ID

local list = {
	134,
	767,
	768,
	769,
	770,
	771,
	772,
	773,
	154,
}

function npc.onTickEndNPC(v)
	local random = math.random(1, #list)
	v:transform(list[random])
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc