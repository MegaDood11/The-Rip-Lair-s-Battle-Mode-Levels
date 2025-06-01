--[[
	Bumper Platform
	Created by Wowsie
]]


local npcManager = require("npcManager")

local bumperPlatform = {}
local npcID = NPC_ID

local bumperPlatformSettings = {
	id = npcID,

	gfxwidth = 96,
	gfxheight = 32,
	width = 96,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	foreground = false,

	
	speed = 1,
	luahandlesspeed = false, 
	nowaterphysics = false,
	cliffturn = false, 
	staticdirection = false, 

	npcblock = false,
	npcblocktop = true,
	playerblock = false,
	playerblocktop = true,

	nohurt=true,
	nogravity = false,
	noblockcollision = true,
	notcointransformable = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,

	score = 1,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false, 
	harmlessthrown = false, 
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,
	lineguided=true,
	lineactivebydefault=true,
	linespeed=3,
}

npcManager.setNpcSettings(bumperPlatformSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_OFFSCREEN,
	} 
);


function bumperPlatform.onInitAPI()
	npcManager.registerEvent(npcID, bumperPlatform, "onTickNPC")
	npcManager.registerEvent(npcID, bumperPlatform, "onDrawNPC")
end

function bumperPlatform.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		
		return
	end

	if not data.initialized then
		data.initialized = true
		data.jump = false
		data.NPCjump = false
		data.playerBounce = 0
		data.NPCBounce = 0
		data.boing = 1
		data.scaleUp = false
		data.scaleDown = false
		data.bumperImage = Graphics.loadImage("npc-994e.png")
		data.SND = Misc.resolveSoundFile("bumper2")
		data.offset = 0
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
	end
	
	if player.standingNPC == v and data.jump == false then
        SFX.play(data.SND)
		data.playerBounce = -35
		data.jump = true
		data.scale = true
	end

	
	for _, npc in ipairs(NPC.getIntersecting(v.x - 2, v.y - 2, v.x + v.width + 2, v.y + v.height + 2)) do
        if Colliders.bounce(npc,v) and NPC.HITTABLE_MAP[npc.id] then
			SFX.play(data.SND)
		    data.NPCBounce = -27
		    data.NPCjump = true
		    data.scale = true
			if data.NPCjump == true then
		        npc.speedY = -16
				
            end
	        
        end
    end
	
	if player:mem(0x14A, FIELD_WORD) == 2 then
		data.playerBounce = 0
	end
	if data.jump == true then
		data.playerBounce = data.playerBounce + 1
		player.speedY = data.playerBounce
	end
	
	if data.playerBounce >= 0 then
		data.jump = false
	end
	if data.NPCBounce >= 0 then
		data.NPCjump = false
	end
	if data.boing >= 1.3 then
		data.scale = false
		data.boing = 1
	end
	if data.scale == true then
		data.boing = data.boing + 0.1
	end
	
	v.friendly = false
end

function bumperPlatform.onDrawNPC(v)
	local data = v.data
	Graphics.drawBox{
			type= RTYPE_IMAGE,
			texture = data.bumperImage,
			x = v.x + 48,
			y = v.y + 16,
			sourceX = 0,

            sourceY = 0,
			sourceWidth = 96,
            sourceHeight = 32,
			sceneCoords = true,
			width = 96 * data.boing,
			height = 32 * data.boing,
			priority = -57,
			centered = true
		}
end

return bumperPlatform