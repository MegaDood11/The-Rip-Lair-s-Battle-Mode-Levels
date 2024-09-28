local npcManager = require("npcManager")
local npc = {}
local id = NPC_ID

local list = {
	19,
	129,
	130,
	--471, --Uncommenting this, Billy Snifits are broken in Patch 2
	530,
	578,
}

function npc.onTickEndNPC(v)
	local random = math.random(1, #list)
	v:transform(list[random])
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
end

return npc