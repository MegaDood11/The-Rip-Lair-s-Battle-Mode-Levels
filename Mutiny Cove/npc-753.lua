--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local poop = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local poopSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 40,
	gfxwidth = 26,
	width = 26,
	height = 32,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	ignorethrownnpcs = true,
}

--Applies NPC settings
npcManager.setNpcSettings(poopSettings)

--Register events
function poop.onInitAPI()
	npcManager.registerEvent(npcID, poop, "onTickNPC")
end

function poop.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	if v.collidesBlockBottom then v:kill(9) end
end

--Gotta return the library table!
return poop