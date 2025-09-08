--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local pirate = require("pirates")

--Create the library table
local friendly = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local friendlySettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 58,
	width = 48,
	height = 48,
	frames = 6,
	idleFrames = 4,
	framestyle = 0,
	framespeed = 8,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	ignorethrownnpcs = true,
	
	sound = "SFX/Parrot.wav",
}

--Applies NPC settings
npcManager.setNpcSettings(friendlySettings)

pirate.register(npcID)

return friendly