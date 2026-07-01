--[[

	spawnzones.lua by Enjl, custom spawnzone editor graphics by Sancles

]]

local blockManager = require("blockManager")
local spawnzones = require("spawnzones")

local spawnzone = {}
local blockID = BLOCK_ID


local spawnzoneSettings = {
	id = blockID,
	
	frames = 1,
	framespeed = 8,


	sizable = true,
	passthrough = true,
}

blockManager.setBlockSettings(spawnzoneSettings)

spawnzones.block = blockID

return spawnzone