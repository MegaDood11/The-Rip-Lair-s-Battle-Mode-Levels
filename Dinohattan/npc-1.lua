--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local sampleNPC = {}

local npcID = NPC_ID


npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
	}, 
	{
		[HARM_TYPE_JUMP]={id=751, yoffset=1, yoffsetBack = 1}
	}
);

return sampleNPC
