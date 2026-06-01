local bones = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

function bones.onTickNPC(v)
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(v,p) and v.heldIndex == 0 then
			p:harm()
		end
	end
end

function bones.onInitAPI()
	npcManager.registerEvent(npcID, bones, "onTickNPC")
end

return bones