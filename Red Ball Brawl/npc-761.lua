local npcManager = require("npcManager")
local grrrolAI = require("npcs/ai/grrrol")

local grrrol = {}

    -----------------------------------------
   -----------------------------------------
  ------- Initialize NPC settings ---------
 -----------------------------------------
-----------------------------------------

local npcID = NPC_ID

local settings = {
	id = npcID,
	gfxheight = 64,
	gfxwidth = 64,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	width = 64, 
	height = 64,
	eyeOffsetX = 1,
	eyeOffsetY = 1,
	noiceball = 0,
	speed=1.3,
	isheavy = 0,
	grrrolstrength = 0,
	cliffturn=1,
	nofireball = false,
	noiceball = true,
	score = 7,
	health = 3
}

local harmtypes = {
	[HARM_TYPE_FROMBELOW]     = NPC_ID,
	[HARM_TYPE_PROJECTILE_USED]    = NPC_ID,
	[HARM_TYPE_NPC]     = NPC_ID,
	[HARM_TYPE_LAVA]     = {id = 13, xoffset = 0.5, xoffsetBack = 0, yoffset = 1, yoffsetBack = 1.5}
}

npcManager.registerHarmTypes(npcID, table.unmap(harmtypes), harmtypes)

grrrolAI.register(settings)

return grrrol