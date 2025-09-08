--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	gfxwidth = 54,
	gfxheight = 54,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 30,
	height = 30,
	--Frameloop-related
	frames = 1,
	gfxoffsety = 12,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,
	
	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	nowalldeath = true, -- If true, the NPC will not die when released in a wall
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

function sampleNPC.onTickNPC(v)
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
		data.timer = 0
		data.rotation = 0
		v.ai3 = 10
	end

	if v.heldIndex == 0 then
	
		if not data.speed then data.speed = true v.speedX = v.speedX * 1.5 end
		
		v.isProjectile = false
		data.timer = data.timer + 1
		
		for _,p in ipairs(Player.get()) do
			for _,n in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
				if v.forcedState == 0 then
					if data.timer >= 384 or v.ai3 <= 3 or (Colliders.collide(p, v) and v:mem(0x12E, FIELD_WORD) <= 0) or (Colliders.collide(n, v) and (n.id >= 752 and n.id <= 765) and not n.friendly) then
						Explosion.spawn(v.x + v.width * 0.5, v.y + v.height * 0.5, 2)
						v:kill(9)
					end
				end
			end
		end
		
		data.rotation = data.rotation + v.speedX * 2
		
		if v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight or v.collidesBlockLeft then
			SFX.play("SFX/Bounce.wav")
		end
		
		if v.speedX == 0 and v.ai3 > 8 then v.ai3 = 8 end
		if v.collidesBlockBottom then
			v.speedY = -v.ai3
			v.ai3 = math.clamp(v.ai3 - 1, 0, 8)
			v.speedX = v.speedX * 0.75
		end
	end
end

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation then return end
	
	data.rotation = data.rotation or 0

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = -45,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			rotation = data.rotation,
			timer = data.timer,
			MutinyLevelSplashSound = data.MutinyLevelSplashSound,
			speed = data.speed,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.rotation = receivedData.rotation
		data.timer = receivedData.timer
		data.MutinyLevelSplashSound = receivedData.MutinyLevelSplashSound
		data.speed = receivedData.speed
	end,
}

--Gotta return the library table!
return sampleNPC