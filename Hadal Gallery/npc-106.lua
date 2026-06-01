local trident = {}
local npcManager = require("npcManager")
local afterimages = require("afterimages")
local battlePlayer = require("scripts/battlePlayer")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

local npcID = NPC_ID

function trident.onTickNPC(v)

	v.speedY = 0
	v.data.culprit = v.heldPlayer or 0
	
	v:mem(0x132,FIELD_WORD, v.heldIndex)
	v.data.culprit = v:mem(0x132,FIELD_WORD)
	
	v:mem(0x132,FIELD_WORD, v.data.culprit)
	
	if v:mem(0x132,FIELD_WORD) ~= 0 then
		v.data.target = v:mem(0x132,FIELD_WORD)
	end

	if v.heldIndex == 0 then
		v.isProjectile = false
		v.y = v.data.y
		v.speedX = math.clamp(v.speedX + 0.4 * v.direction, -12, 12)
		afterimages.create(v, 24, Color.red, true, -49)
		
		local tbl = Block.SOLID .. Block.PLAYER
		local collidingBlocks = Colliders.getColliding {
			a = v,
			b = tbl,
			btype = Colliders.BLOCK
		}

		if #collidingBlocks > 0 then --Not colliding with something
			v:kill()
			Effect.spawn(10,v.x + v.width * 0.5,v.y)
			SFX.play(Misc.resolveSoundFile("character/ub_drop"))
			
			for _,b in ipairs(collidingBlocks) do
				b:hit(true)
			end
		end
		
		for _,n in NPC.iterate() do
			if Colliders.collide(v, n) and n.id ~= v.id and NPC.HITTABLE_MAP[n.id] then
				n:harm()
				v:kill()
				Effect.spawn(10,v.x + v.width * 0.5,v.y)
				SFX.play(Misc.resolveSoundFile("character/ub_drop"))
			end
		end
	else
		v.data.y = v.y
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
			y = data.y,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end
		data.culprit = receivedData.culprit
		data.target = receivedData.target
		data.y = receivedData.y
	end,
}

function trident.onInitAPI()
	npcManager.registerEvent(npcID, trident, "onTickNPC")
end

return trident