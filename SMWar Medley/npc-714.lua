local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

local hammer = {}
local npcID = NPC_ID

function hammer.onInitAPI()
	npcManager.registerEvent(npcID, hammer, "onTickNPC")
end

function hammer.onTickNPC(v)
	if v.despawnTimer <= 0 then
		return
	end

	-- Projectile cooldown for player that threw the hammer
	--[[if v.ai5 > 0 then
		local p = Player(v.ai5)

		if p.character == CHARACTER_TOAD and p.powerup == POWERUP_HAMMER then
			p:mem(0x160,FIELD_WORD,math.max(p:mem(0x160,FIELD_WORD),20))
		end
	end]]

	-- Eventually die
	local data = v.data

	data.lifetime = data.lifetime or 128

	if v.data._basegame.falling then
		data.lifetime = data.lifetime - 1
		if data.lifetime <= 0 then
			Effect.spawn(10,v.x + v.width*0.5 - 16,v.y + v.height*0.5 - 16)
			onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
		end
	end
	--Colliders.getHitbox(v):draw()
end

return hammer