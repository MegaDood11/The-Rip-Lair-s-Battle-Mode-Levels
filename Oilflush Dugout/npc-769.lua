local npcManager = require("npcManager")
local AI = require("AI/tackleFireGenerator")

local sampleNPC = {}
local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	frames = 2,
	framespeed = 8,
	framestyle = 0,

	gfxwidth = 32,
	gfxheight = 32,

	width = 28,
	height = 28,

	--nohurt = true,
	nofireball = true,
	noiceball = false,
	nogravity = true,
	noblockcollision = true,
	nowaterphysics = true,

	jumphurt = true,
	spinjumpsafe = true,
	--ignorethrownnpcs = true,
	--harmlessgrab = true,
	--harmlessthrown = true,
	--luahandlesspeed = true,
	terminalvelocity = 32,
	ishot = true,

	trailEffect = 265,
	priority = -66,
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
	}, 
	{
		[HARM_TYPE_NPC] = 10,
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_HELD] = 10,
		[HARM_TYPE_TAIL] = 10,
		[HARM_TYPE_OFFSCREEN] = nil,
	}
);

AI.registerProjectile(npcID)

return sampleNPC