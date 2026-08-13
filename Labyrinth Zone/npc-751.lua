--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local onlinePlayNPC = require("scripts/onlinePlay_npc")

local ai = require("monitor_ai")


local monitor = {}
local npcID = NPC_ID


local monitorSettings = table.join({
	id = npcID,

	frames = 1,


	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	ignorethrownnpcs = true,
	jumphurt = true,
	noblockcollision=true,
	nogravity=true,

	lightradius = 0,
},ai.sharedSettings)


npcManager.setNpcSettings(monitorSettings)
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})


ai.registerBroken(npcID)

--Register events
function monitor.onInitAPI()
	npcManager.registerEvent(npcID, monitor, "onTickNPC")
end

function monitor.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	v.despawnTimer = 180
	v.ai1 = v.ai1 + 1
	v.x = v.spawnX
	v.y = v.spawnY
	
	if v.ai1 >= 64*30 then
		onlinePlayNPC.forceKillNPC(v,HARM_TYPE_OFFSCREEN)
		Effect.spawn(10, v.x, v.y + v.height * 0.5)
		NPC.spawn(753, v.x, v.y, player.section, true)
	end
	
	data.setRespawnTime = false
end

return monitor