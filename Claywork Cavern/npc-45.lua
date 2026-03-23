local iceBlock = {}
local npcManager = require("npcManager")
local onlineNPC = require("scripts/onlinePlay_npc")

local npcID = NPC_ID

function iceBlock.onNPCKill(e, v, r)
	if Defines.levelFreeze then return end
	if v.id ~= npcID or r == 9 then return end
	local n = NPC.spawn(npcID, v.spawnX, v.spawnY)
	n.data.respawn = 320
	onlineNPC.forceKillNPC(v)
end

function iceBlock.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data
	if not data.respawn then return end
	data.respawn = data.respawn - 1
	v.x = v.spawnX
	v.y = v.spawnY
	v.speedX = 0
	v.ai1 = 0
	v.ai2 = 1
	v.animationFrame = -1
	v.friendly = true
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(v,p) then return end
		if data.respawn <= 0 then
			Effect.spawn(10, v.x, v.y)
			data.respawn = nil
			v.friendly = false
			break
		end
	end
end

function iceBlock.onInitAPI()
	npcManager.registerEvent(npcID, iceBlock, "onTickEndNPC")
	registerEvent(iceBlock, "onNPCKill")
end

return iceBlock