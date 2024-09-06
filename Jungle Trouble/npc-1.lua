--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
	},
	{
	[HARM_TYPE_FROMBELOW]=800,
	[HARM_TYPE_NPC]=800,
	[HARM_TYPE_PROJECTILE_USED]=800,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	[HARM_TYPE_HELD]=800,
	[HARM_TYPE_TAIL]=800,
	}
);

--Gotta return the library table!
return sampleNPC