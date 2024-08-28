local npcManager = require("npcManager")
local balls = require("AI/huckitBalls")
local ball = {}
local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})

-- settings
local config = {
	id = npcID,  
	width = 24, 
    height = 24,
    gfxwidth = 24,
    gfxheight = 24,
    frames = 2,
    framestyle = 0,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
    nogravity = false,
    spinjumpsafe = true,
    noblockcollision = false,
    score = 0
}
npcManager.setNpcSettings(config)

npcManager.registerHarmTypes(npcID,
{
    HARM_TYPE_JUMP,
    HARM_TYPE_SPINJUMP,
    HARM_TYPE_TAIL,
    HARM_TYPE_NPC,
    HARM_TYPE_PROJECTILE_USED,
    HARM_TYPE_HELD,
    HARM_TYPE_SWORD,
}, 
{
    [HARM_TYPE_JUMP]=10,
    [HARM_TYPE_TAIL]=10,
    [HARM_TYPE_NPC]=10,
    [HARM_TYPE_PROJECTILE_USED]=10,
    [HARM_TYPE_HELD]=10,
    [HARM_TYPE_SWORD]=10,
}
);

balls.register(npcID)

return ball