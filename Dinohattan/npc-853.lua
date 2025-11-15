--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local missileAI = require("AI/missileBill")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	gfxheight = 180,
	gfxwidth = 48,

	width = 32,
	height = 144,

	frames = 1,
	framestyle = 0,
	framespeed = 8,
	speed = 0,

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	ignorethrownnpcs = true,
	luahandlesspeed = true,
	staticdirection = true,

	canhurt = true, -- nohurt needs to be true, so this is an alternative
	priority = -45,
	sparkParticleFile = Misc.resolveFile("p_missileBill.ini"),
	smokeParticleFile = Misc.resolveFile("p_missileSmoke.ini"),
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,	{HARM_TYPE_OFFSCREEN}, {[HARM_TYPE_OFFSCREEN] = 10})

missileAI.registerNPC(npcID)

return sampleNPC