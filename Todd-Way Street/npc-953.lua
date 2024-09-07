local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local battleStars = require("scripts/battleStars")


local star = {}
local npcID = NPC_ID

local starSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 2,
	framestyle = 0,
	framespeed = 6,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = false,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	notcointransformable = true,
	ignorethrownnpcs = true,

	isinteractable = true,


	lightradius = 128,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,


	sparkleTime = 16,

	isDropped = false,
}

npcManager.setNpcSettings(starSettings)
npcManager.registerHarmTypes(npcID,{},{})

battleStars.registerCollectable(npcID)

battleStars.collectableSpawnID = npcID

return star