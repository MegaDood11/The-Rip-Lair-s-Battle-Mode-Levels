local bones = {}
local npcManager = require("npcManager")
local battlePlayer = require("scripts/battlePlayer")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

local npcID = NPC_ID

function bones.onTickNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data
	
	v.friendly = true
	v.isProjectile = false
	v.speedY = 0
	data.despawn = data.despawn or 640
	
	data.despawn = data.despawn - 1
	if data.despawn <= 0 then
		v:kill(9)
		Effect.spawn(10, v.x, v.y)
	end
	
	v.data.culprit = v.heldPlayer or 0
	
	v:mem(0x132,FIELD_WORD, v.heldIndex)
	v.data.culprit = v:mem(0x132,FIELD_WORD)
	
	v:mem(0x132,FIELD_WORD, v.data.culprit)
	
	if v:mem(0x132,FIELD_WORD) ~= 0 then
		v.data.target = v:mem(0x132,FIELD_WORD)
	end
	
	for _,p in ipairs(Player.get()) do
		if p.idx ~= v.data.target and Colliders.collide(v,p) and v.heldIndex == 0 then
			battlePlayer.harmPlayer(p,1)
		end
	end
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			culprit = data.culprit,
			target = data.target,
			despawn = data.despawn,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end
		data.culprit = receivedData.culprit
		data.target = receivedData.target
		data.despawn = receivedData.despawn
	end,
}

function bones.onInitAPI()
	npcManager.registerEvent(npcID, bones, "onTickNPC")
end

return bones