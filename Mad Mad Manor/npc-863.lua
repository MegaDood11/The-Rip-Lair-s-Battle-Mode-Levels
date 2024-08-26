--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local piano = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local pianoSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 120,
	gfxwidth = 144,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 108,
	height = 78,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 6,
	--Frameloop-related
	frames = 1,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(pianoSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

--Register events
function piano.onInitAPI()
	npcManager.registerEvent(npcID, piano, "onTickNPC")
end

local sound = Misc.resolveFile("Madpiano.ogg")

function piano.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		v.ai1 = 0
		v.ai2 = 0
		return
	end
	
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		--Set this to 4 so it doesnt immediately play the sound when the level loads
		v.ai2 = 4
	end
	
	v.ai2 = v.ai2 - 1
	if v.collidesBlockBottom then
		v.ai1 = v.ai1 + 1
		if v.ai1 == 1 and v.ai2 <= 0 then
			SFX.play(sound)
		end
	else
		v.ai1 = 0
	end
	
end

--Gotta return the library table!
return piano