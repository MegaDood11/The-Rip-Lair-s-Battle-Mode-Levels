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
	nogravity = false,
	noblockcollision = false,
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


	lightradius = 64,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,


	sparkleTime = 16,

	isDropped = true,

	droppedMinSpeedX = 1,
	droppedMaxSpeedX = 2.5,
	droppedMinSpeedY = -10,
	droppedMaxSpeedY = -5,

	bounceMinSpeedY = -8,
	bounceMaxSpeedY = -4,

	pitBounceSpeed = -14,

	rotationSpeed = 4,

	lifetime = 512,
	flickerTime = 48,
}

npcManager.setNpcSettings(starSettings)
npcManager.registerHarmTypes(npcID,{},{})

battleStars.registerCollectable(npcID)

battleStars.droppedSpawnID = npcID

return star