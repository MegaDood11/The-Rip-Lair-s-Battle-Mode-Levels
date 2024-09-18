--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--No onTickNPC or onTickEndNPC since it's just the vanilla Koopa AI
function sampleNPC.onInitAPI()
	registerEvent(sampleNPC, "onNPCHarm")
end

--Cancel death by spinjumps
function sampleNPC.onNPCHarm(eventObj, v, killReason, culprit)
	if npcID ~= v.id or v.isGenerator then return end

	if killReason == HARM_TYPE_SPINJUMP then
		eventObj.cancelled = true
	elseif killReason == HARM_TYPE_SWORD and player:isGroundTouching() and player:mem(0x12E, FIELD_BOOL) then
		eventObj.cancelled = true
	end
end
--Gotta return the library table!
return sampleNPC