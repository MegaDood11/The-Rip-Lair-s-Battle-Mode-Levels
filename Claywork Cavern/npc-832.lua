local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local switch = require("eventSwitch")


local star = {}
local npcID = NPC_ID

local starSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	frames = 1,
	framestyle = 0,
	framespeed = 8, 
	speed = 1,
	
	npcblock = true,
	npcblocktop = true, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	grabside=false,
	grabtop=false,
	notcointransformable = true,
	score = 0,
}

npcManager.setNpcSettings(starSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
	}, 
	{
		[HARM_TYPE_JUMP]=npcID,
	}
);

--Register events
function star.onInitAPI()
	registerEvent(star, "onNPCHarm")
end

function star.onNPCHarm(eventObj, v, killReason)
	if v.id ~= npcID then return end
	if killReason == HARM_TYPE_FROMBELOW then eventObj.cancelled = true SFX.play(2) v.speedY = -4 end
	if killReason == HARM_TYPE_JUMP then
		SFX.play(32)
		triggerEvent("Hide")
	end
end

switch.collectableSpawnID = npcID

return star