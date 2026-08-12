--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Register events
function sampleNPC.onInitAPI()
	registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onNPCKill(eventObj, v, reason)
	if v.id ~= npcID then return end
	if reason == HARM_TYPE_OFFSCREEN then return end
	SFX.play(Misc.resolveSoundFile("sonic-break"))
	Effect.spawn(751, v.x, v.y)
end

--Gotta return the library table!
return sampleNPC