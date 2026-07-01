local npcManager = require("npcManager")
local spout = require("spout")

local sandspout = {}
local npcID = NPC_ID

local settings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 192,
	width = 192,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 4,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	npcblocktop = false,
	playerblocktop = false,
	nohurt=true,
	spinjumpsafe = false,
	
	lava=true, --If enabled, kills the player on contact
	forcerise=true, --If enabled, makes the player rise when underneath
	fall=true,
}

spout.register(settings)

return sandspout