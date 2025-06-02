local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local AI = require("AI/sentry")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID, 

	gfxwidth = 192, 
	gfxheight = 320,

	width = 192, 
	height = 320,

	frames = 6,
	framespeed = 16,
	framestyle = 0,

	score = 0,

	nogravity = true,
	noblockcollision = true;
	jumphurt = true,
	spinjumpsafe = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nohurt = true,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	notcointransformable = true,
	nowaterphysics = true,
	ignorethrownnpcs = true,
	isflying = true,

	priority = -95,
	delay = 128,
	crossHairImg = Graphics.loadImageResolved("npc-"..npcID.."-crossHair.png"),
	warningImg = Graphics.loadImageResolved("npc-"..npcID.."-warning.png"),
	shineImg = Graphics.loadImageResolved("npc-"..npcID.."-shine.png"),
	overlayImg = Graphics.loadImageResolved("npc-"..npcID.."-overlay.png"),
	targetLockedSFX = {id = "targetLocked.ogg", volume = 1},

	-- these settings are for the cross hair
	radius = 48,
	lerpTime = 32,
	crossHairFramespeed = 8,
	crossPriority = 0,
	idleFrames = 1,
	lockingFrames = 3,
	lockedFrames = 1,
	followSpeed = 5,
	warnTime = 32,
	shineTime = 32,
	waitTime = 8,
	rotationTime = 24,

	explosionRadius = 48,
	explosionEffect = npcID,
	explosionSFX = {id = 43, volume = 1},
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,	{}, {});

AI.register(npcID)

return sampleNPC