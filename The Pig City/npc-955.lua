local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local battlePlayer = require("scripts/battlePlayer")
local battleStone = require("scripts/battleStone")
local onlinePlay = require("scripts/onlinePlay")


local stoneNPC = {}
local npcID = NPC_ID

local stoneNPCSettings = {
	id = npcID,
	
	gfxwidth = 54,
	gfxheight = 60,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 34,
	height = 52,
	
	frames = 4,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = false,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = false,

	notcointransformable = false,
	ignorethrownnpcs = false,
	staticdirection = false,
	luahandlesspeed = false,

	grabside = true,
	grabtop = true,


	lightradius = 128,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,


	highlightWaitTime = 192,

	playerMaxJumpForce = {
		[CHARACTER_MARIO] = 12,
		[CHARACTER_LUIGI] = 14,
		[CHARACTER_PEACH] = 12,
		[CHARACTER_TOAD] = 10,
	},

	playerMaxSpeed = 3,
	playerMaxJumpForce = 12,
	playerGravity = 0.2,

	landSound = Misc.resolveSoundFile("bowlingball"),
	shockwaveID = npcID + 1,
	shockwaveCooldown = 64,

	bubbleImage = Graphics.loadImageResolved("resources/bubble.png"),
	bubblePopEffectID = 952,

	droppedPlayerStunTime = 40,

	overheatWarningSound = Misc.resolveSoundFile("resources/explosionWarning"),
	overheatWarningSoundTime = 192,
	totalOverheatTime = 64*45,

	overheatEffectTime = 256,
	overheatFlashColorA = Color.fromHexRGB(0xFF7B00),
	overheatFlashColorB = Color.fromHexRGB(0xFFB800),

	overheatSwapReduction = 0.75,

	warpCooldownMultiplier = 4,
}

npcManager.setNpcSettings(stoneNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_JUMP]            = 10,
		[HARM_TYPE_FROMBELOW]       = 10,
		[HARM_TYPE_NPC]             = 10,
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]            = 10,
		[HARM_TYPE_TAIL]            = 10,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

battleStone.registerNPC(npcID)

return stoneNPC