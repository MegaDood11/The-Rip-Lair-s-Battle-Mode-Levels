--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")

local onlinePlayNPC = require("scripts/onlinePlay_npc")

local walker = require("pianta assets - do not extract/walkerAI_pianta")

local mask = Graphics.loadImageResolved("pianta assets - do not extract/pianta_goner.png")
local glasses = Graphics.loadImageResolved("pianta assets - do not extract/pianta_glasses.png")
local moustache = Graphics.loadImageResolved("pianta assets - do not extract/pianta_moustache.png")
local hat = Graphics.loadImageResolved("pianta assets - do not extract/pianta_hat.png")
local talk = Graphics.loadImageResolved("hardcoded-43.png")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 18,
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
	nofireball = false,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	ignorethrownnpcs = true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

local characterSpeedOffsets = {
	
	--Mario
	[1] = vector.v2(1, 1),
	
	--Luigi
	[2] = vector.v2(0.95, 0.95),
	
	--Peach
	[3] = vector.v2(2, 1.05),
	
	--Toad
	[4] = vector.v2(2, 1.05),
	
	--Link
	[5] = vector.v2(2, 1.05),
}


-- Edit this if you want to change how their walking frames are
walker.register(npcID, {
    count={1,2,2},
    speed={8,8,8},
    offset={
        [-1]={0,0,2},
        [1]={sampleNPCSettings.frames,sampleNPCSettings.frames,sampleNPCSettings.frames + 2}
    },
})


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onTick")
end

-- Detects if the player is on the ground, the redigit way. Function by MrDoubleA
local function isOnGround(p)
	return (
		p.speedY == 0 -- "on a block"
		or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
		or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
	)
end

function sampleNPC.onTick()
	for _,p in ipairs(Player.get()) do
		if not p.data.chuckedByAChuckster then return end
		if p.character <= 2 then
			p:mem(0x3C, FIELD_BOOL, true)
		end
		p.keys.left = KEYS_UP
		p.keys.right = KEYS_UP
		p.keys.jump = KEYS_UP
		p.keys.altJump = KEYS_UP
		p.keys.run = KEYS_UP
		p:mem(0x154, FIELD_WORD, false)
		if isOnGround(p) then p.data.chuckedByAChuckster = nil end
	end
end

function sampleNPC.onTickEndNPC(v)

	local data = v.data
	local settings = v.data._settings
	
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
		data.turnTimer = 0
		data.stopTimer = 0
		data.imAChuckster = false
		data.chucksterTimer = 0
	end

	data.canTalk = false
	data.talkTimer = data.talkTimer or 0
	data.talkTimer = data.talkTimer - 1
	
	for _,p in ipairs(Player.get()) do
		if Colliders.collide(p, v) and settings.chuckster then
			data.canTalk = true
			if p.keys.up == KEYS_PRESSED and data.talkTimer <= 0 then
				data.imAChuckster = true
				data.victim = Player.getNearest(v.x + v.width * 0.5, v.y + v.height * 0.5)
				data.victim.current = vector(data.victim.x, data.victim.y)
				data.talkTimer = 192
			end
		end
	end

	if settings.behaviour == 0 then
		v.animationFrame = math.floor(math.floor(lunatime.tick() / 12) % 6 + 4)
	elseif settings.behaviour == 3 then
		v.animationFrame = math.floor(math.floor(lunatime.tick() / 12) % 6 + 10)
	elseif settings.behaviour == 2 then
	
		v.speedX = 1.5 * v.direction
		
		if settings.patrol > 0 and data.turnTimer >= settings.patrol * 21 then
			data.turnTimer = -data.turnTimer
			data.stopTimer = 1
		end
		
		v.animationFrame = math.floor(math.floor(lunatime.tick() / sampleNPCSettings.framespeed) % 2)
		
		if data.stopTimer > 0 then
			data.stopTimer = data.stopTimer + 1
			v.speedX = 0
			v.animationFrame = 0
			if data.stopTimer >= 32 then
				v.direction = -v.direction
				data.stopTimer = 0
			end
		else
			data.turnTimer = data.turnTimer + 1
		end
	end
	
	if data.imAChuckster then
		data.chucksterTimer = 1
		data.imAChuckster = false
	end
	
	if data.chucksterTimer > 0 and data.victim then
		data.chucksterTimer = data.chucksterTimer + 1
		v.speedX = 0
		--Move to the NPC's position
		if data.chucksterTimer > 2 then
			if data.chucksterTimer <= 17 then
				data.victim.x = easing.outQuad(data.chucksterTimer, data.victim.current.x, (v.x) - data.victim.current.x, 16)
				data.victim.y = easing.outQuad(data.chucksterTimer, data.victim.current.y, (v.y - (data.victim.height - 48)) - data.victim.current.y, 16)
			else
				data.victim.data.chuckedByAChuckster = true
				v.animationFrame = math.floor((data.chucksterTimer - 16) / 8) % 2 + 16
				if data.chucksterTimer == 18 then
				
					if settings.throwDirection <= 2 then
						data.chucksterDir = settings.throwDirection - 1
						if settings.throwDirection == 1 then data.chucksterDir = RNG.irandomEntry{-1,1} end
					elseif settings.throwDirection == 3 then
						data.chucksterDir = v.direction
					else
						data.chucksterDir = -v.direction
					end
				
					SFX.play(24)
					data.victim.speedX = (settings.xSpeed * (characterSpeedOffsets[data.victim.character].x) or 1) * data.chucksterDir
					v.direction = math.sign(data.victim.speedX)
					data.victim.speedY = -settings.ySpeed * (characterSpeedOffsets[data.victim.character].y) or 1
				end
				if data.chucksterTimer >= 33 then
					data.chucksterTimer = 0
				end
			end
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

local function isDespawned(v)
	return v.despawnTimer <= 0
end

--[[************************
Rotation code by MrDoubleA
**************************]]

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
	--Code by Marioman, cause it was there
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	
	data.color = settings.color or 0
	
	data.age = settings.age + 1
	
	if settings.glasses then
		drawSprite{
		texture = glasses,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + (data.age * 8) - 8,
		width = config.gfxwidth / math.clamp((data.age / 1.7), 1, 2), height = config.gfxheight / math.clamp((data.age / 1.5), 1, 2),

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = -44.9,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
		}
	end
	
	if settings.moustache then
		drawSprite{
		texture = moustache,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + (data.age * 8) - 8,
		width = config.gfxwidth / math.clamp((data.age / 1.7), 1, 2), height = config.gfxheight / math.clamp((data.age / 1.5), 1, 2),

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = -44.9,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
		}
	end

	local Width = config.gfxwidth
	local SourceX = data.color * Width

	if not isDespawned(v) then
		drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + (data.age * 8) - 8,
		width = config.gfxwidth / math.clamp((data.age / 1.7), 1, 2), height = config.gfxheight / math.clamp((data.age / 1.5), 1, 2),

		sourceX = SourceX,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = -45,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}
	end
	
	if settings.hat > 0 then
		drawSprite{
		texture = hat,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + (data.age * 8) - 8,
		width = config.gfxwidth / math.clamp((data.age / 1.7), 1, 2), height = config.gfxheight / math.clamp((data.age / 1.5), 1, 2),

		sourceX = (settings.hat - 1) * Width,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = -44.9,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
		}
	end
	
	if data.canTalk then
		data.talk = data.talk or Sprite{texture = talk, frames = 1}
		data.talk.position = vector(v.x + v.width * 0.375, v.y - v.height)
		data.talk:draw{sceneCoords = true, frame = 1, priority = -47}
	end
	
	npcutils.hideNPC(v)
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			imAChuckster = data.imAChuckster,
			initialized = data.initialized,
			turnTimer = data.turnTimer,
			stopTimer = data.stopTimer,
			imAChuckster = data.imAChuckster,
			chucksterTimer = data.chucksterTimer,
			chucksterDir = data.chucksterDir,
			age = data.age,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.imAChuckster = receivedData.imAChuckster
		data.initialized = receivedData.initialized
		data.turnTimer = receivedData.turnTimer
		data.stopTimer = receivedData.stopTimer
		data.imAChuckster = receivedData.imAChuckster
		data.chucksterTimer = receivedData.chucksterTimer
		data.chucksterDir = receivedData.chucksterDir
		data.age = receivedData.age
	end,
}

--Gotta return the library table!
return sampleNPC