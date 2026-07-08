local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")
local npc = {}
local id = NPC_ID

function npc.onTickNPC(v)
	
	local data = v.data
	
	if not data.list then
		data.list = {
			153,
			153,
			33,
			33,
			952,
			957,
			287,
			287,
		}
	end

	local random = math.random(1, #data.list)
	v:transform(data.list[random])
	if v.id == 33 then
		v.ai1 = 1
		v.speedX = RNG.random(-2,2)
		v.speedY = -6
	end
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onTickNPC')
end

onlinePlayNPC.onlineHandlingConfig[id] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			list = data.list,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end
		data.list = receivedData.list
	end,
}

return npc