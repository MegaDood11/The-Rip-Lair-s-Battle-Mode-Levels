--[[

	Extended Goombas
	Made by DeviousQuacks23

	See extendedGoombas.lua for full credits.

]]

local npcManager = require("npcManager")

local extendedGoombas = require("extendedGoombas")

local goomba = {}
local npcID = NPC_ID

local deathEffect = (777)
local stompEffect = (776)

local goombaSettings = table.join({
	id = npcID,

	gfxwidth = 32,
	gfxheight = 48,

	gfxoffsetx = 0,
	gfxoffsety = 2,
	
	width = 32,
	height = 32,
	
	frames = 2,
	framestyle = 0,
	framespeed = 8,

    	jumphurt = true,
    	spinjumpsafe = true,
},extendedGoombas.sharedSettings)

npcManager.setNpcSettings(goombaSettings)
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	},
	{
		[HARM_TYPE_JUMP]            = stompEffect,
		[HARM_TYPE_FROMBELOW]       = deathEffect,
		[HARM_TYPE_NPC]             = deathEffect,
		[HARM_TYPE_PROJECTILE_USED] = deathEffect,
		[HARM_TYPE_HELD]            = deathEffect,
		[HARM_TYPE_TAIL]            = deathEffect,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

extendedGoombas.register(npcID)

return goomba