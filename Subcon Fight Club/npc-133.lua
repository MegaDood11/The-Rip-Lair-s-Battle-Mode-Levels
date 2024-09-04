local bullet = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

local onlinePlayNPC = require("scripts/onlinePlay_npc")

function bullet.onTickNPC(v)
	if v.despawnTimer <= 0 then
		return
	end
	
	v.friendly = false
	
	local data = v.data

	data.lifetime = (data.lifetime or 256) - 1

	if data.lifetime <= 0 then
		Effect.spawn(10,v.x + v.width*0.5 - 16,v.y + v.height*0.5 - 16)
		onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
	end
end

function bullet.onInitAPI()
	npcManager.registerEvent(npcID, bullet, "onTickNPC")
end

return bullet