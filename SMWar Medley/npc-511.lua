local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

local fireball = {}
local npcID = NPC_ID

function fireball.onInitAPI()
	npcManager.registerEvent(npcID, fireball, "onTickNPC")
end

function fireball.onTickNPC(v)
	if v.despawnTimer <= 0 then
		return
	end

	-- Projectile cooldown for player that threw the fireball
	--[[if v.ai5 > 0 then
		local p = Player(v.ai5)

		if p.character == CHARACTER_TOAD and p.powerup == POWERUP_fireball then
			p:mem(0x160,FIELD_WORD,math.max(p:mem(0x160,FIELD_WORD),20))
		end
	end]]

	-- Eventually die
	local data = v.data

	data.lifetime = (data.lifetime or 128) - 1

	if data.lifetime <= 0 then
		Effect.spawn(10,v.x + v.width*0.5 - 16,v.y + v.height*0.5 - 16)
		onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
	end

	--Colliders.getHitbox(v):draw()
end

return fireball