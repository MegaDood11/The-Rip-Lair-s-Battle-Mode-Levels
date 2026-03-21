--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local firework = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local fireworkSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 22,
	gfxwidth = 14,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 14,
	height = 14,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 8,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
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

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(fireworkSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=78,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local particles = require("particles")

--local fireworkParticle1 = particles.Emitter(0,0,Misc.resolveFile('particles_firework1.ini'))
--local fireworkParticle2 = particles.Emitter(0,0,Misc.resolveFile('particles_firework2.ini'))
local folderPath = "AI/hanabihai/"

local fireworkSFX = folderPath .. "fireworks_explode1.ogg" 


local fireworkAI = require(folderPath.."hanabihai")
local fireworksprites = Graphics.loadImageResolved(folderPath.."firework.png")
local overlaysprites = Graphics.loadImageResolved(folderPath.."fireworkoverlay.png")

local fireworkExplosion = Explosion.register(823, 78, 78, fireworkSFX, true, true)


--Register events
function firework.onInitAPI()
	npcManager.registerEvent(npcID, firework, "onTickNPC")
	--npcManager.registerEvent(npcID, firework, "onTickEndNPC")
	npcManager.registerEvent(npcID, firework, "onDrawNPC")
	--registerEvent(firework, "onNPCKill")
end


function firework.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end
	if not data.effecttimer then
		data.effecttimer = 0
	end
	
	if not data.colourType then
		data.colourType = 1
		data.colour = Color.white
	
	end
	

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
	
	end
	
	if v.speedY < 0 then
			v.speedY = v.speedY * 0.97
				if data.effecttimer == 0 then
					local effect = Effect.spawn(78,v.x + v.width * 0.5, v.y - 6)
					data.effecttimer = 10
				else
					data.effecttimer = data.effecttimer - 1
				end
			--effect.speedY = v.speedY
		end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if v.speedY >= -1 then		-- if it came to a stop, then explode!
		Explosion.spawn(v.x, v.y, fireworkExplosion)
		fireworkAI.drawParticles(v.x+v.width*0.5,v.y+v.height*0.5,data.colourType,data.colour)
		--[[for i = 1, 12 do
			local speedX = math.cos(i*math.pi / (2.5/12))
			local speedY = math.sin(i*math.pi / (2.5/12))
			data.fireworkParticle1:setParam("speedX",speedX * 50)
			data.fireworkParticle1:setParam("speedY",speedY * 50)
			data.fireworkParticle1:Emit(1)
			--Misc.dialog(speedX)
			
		end ]]--
		v:kill()
	end
end

function firework.onDrawNPC(v)
	if v.isHidden or (not v.data.initialized) or not v.data.colourType then return end
	local data = v.data
	
	
	Graphics.drawBox{			-- draw the base
		texture      = fireworksprites,
		sceneCoords  = true,
		x            = v.x + (v.width / 2),
		y            = v.y + (v.height) + 4,
		width        = 14,
		height       = 22,
		sourceX      = 7  * (data.colourType-1),
		sourceY      = 0,
		sourceWidth  = 7,
		sourceHeight = 11,
		centered     = true,
		priority     = -45,
		color        = data.colour .. 1,--playerOpacity,
		rotation     = 0,
	}
	if data.colourType == 4 then		-- draw the overlay (the white shine) if it uses a custom colour
		Graphics.drawBox{			-- draw the base
			texture      = overlaysprites,
			sceneCoords  = true,
			x            = v.x + (v.width / 2),
			y            = v.y + (v.height) + 4,
			width        = 14,
			height       = 22,
			sourceX      = 0,
			sourceY      = 0,
			sourceWidth  = 7,
			sourceHeight = 11,
			centered     = true,
			priority     = -44,
			color        = Color.white .. 1,--playerOpacity,
			rotation     = 0,
		}
	end

end

--Gotta return the library table!
return firework