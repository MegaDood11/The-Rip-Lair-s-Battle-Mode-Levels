--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local tire = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local tireSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 90,
	gfxwidth = 90,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 80,
	height = 80,
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
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	ignorethrownnpcs = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(tireSettings)

--Register events
function tire.onInitAPI()
	npcManager.registerEvent(npcID, tire, "onTickEndNPC")
	npcManager.registerEvent(npcID, tire, "onDrawNPC")
end

--Uses a function by MrDoubleA, so credits to him.
local function getSlopeAngle(v)
	for _,b in ipairs(Block.getIntersecting(v.x,v.y + v.height,v.x + v.width,v.y + v.height + 0.2)) do
		if Block.SLOPE_LR_FLOOR_MAP[b.id] then
			return math.deg(math.atan2(
				(b.y) - (b.y + b.height),
				(b.x + b.width) - (b.x)
			))
		elseif Block.SLOPE_RL_FLOOR_MAP[b.id] then
			return math.deg(math.atan2(
				(b.y + b.height) - (b.y),
				(b.x + b.width) - (b.x)
			))
		end
	end
end

function tire.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.cantMove = nil
		data.bounce = 0
		data.rotation = 0
		data.reverseTimer = 1
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v.speedX = 0
		v.speedY = 0
		v.data.bounced = false
	end
	
	--Stuff to make it into a platform
	v.data.bounced = v.data.bounced or false
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		v.data.bounced = false
		return
	end

	v.despawnTimer = 180

	--Bounce the player
		if (not NPC.config[npcID].playerblocktop) then
		for _,p in ipairs(Player.get()) do
			if Colliders.speedCollide(p,v) and p.speedY > 1 and p.y < v.y - (p.height/2) then
				if p.jumpKeyPressing or p.altJumpKeyPressing then
					p.data.FRIENDINSIDEMEBALL = 48
				else
					p.speedY = -6.5
				end
				SFX.play("Tyre bounce.wav")
				v.data.bounced = true
				data.rotation = 0
				data.bounceTimer = 15
				data.bounce = 0
				data.reverseTimer = 1
			end
			
			if p.data.FRIENDINSIDEMEBALL then
				p.data.FRIENDINSIDEMEBALL = p.data.FRIENDINSIDEMEBALL - 1
				
				if p.data.FRIENDINSIDEMEBALL <= 0 then
					p.data.FRIENDINSIDEMEBALL = nil
				end
				
				if p.jumpKeyPressing or p.altJumpKeyPressing then
					p.speedY = -16
				else
					p.data.FRIENDINSIDEMEBALL = nil
				end
			end
		end
	end
	
	--If a player touches it then push it around
	for _,plr in ipairs(Player.get()) do
		if Colliders.collide(plr, v) then
			if plr.speedX ~= 0 and plr.y > v.y and not data.cantMove then
				v.speedX = plr.speedX * 1.5
				data.bounce = 0
				data.bounceTimer = 0
			end
		end
	end
	
	data.rotation = (data.rotation or 0) + v.speedX
	
	data.bounceTimer = (data.bounceTimer or 0) - 1
	
	if data.bounceTimer > 0 then data.bounce = data.bounce + 8 * data.reverseTimer
		if data.bounceTimer <= 8 then data.reverseTimer = -1 end
	end
	
	if v.x > -197408 then
		v.y = -200480
		v.x = -197408 - 1
		v.direction = -1
		v.speedX = -7
		v.speedY = -7
		data.cantMove = true
	end
	
	if data.cantMove and v.collidesBlockBottom then data.cantMove = nil end
	
	--Stuff to deal with speed
	for _,b in ipairs(Block.getIntersecting(v.x,v.y + v.height,v.x + v.width,v.y + v.height + 0.2)) do
		if Block.SLOPE_LR_FLOOR_MAP[b.id] or Block.SLOPE_RL_FLOOR_MAP[b.id] then
			v.speedX = v.speedX + ((getSlopeAngle(v) or 0) / 350)
		else	
			if math.abs(v.speedX) > 0.035 then
				v.speedX = v.speedX - 0.035 * v.direction
			else
				v.speedX = 0
			end
		end
	end
	
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

function tire.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation then return end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + data.bounce / 2,
		width = config.gfxwidth + data.bounce,height = config.gfxheight - data.bounce,

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
			cantMove = data.cantMove,
			bounce = data.bounce,
			rotation = data.rotation,
			bounced = data.bounced,
			bounceTimer = data.bounceTimer,
			reverseTimer = data.reverseTimer,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.cantMove = receivedData.cantMove
		data.bounce = receivedData.bounce
		data.rotation = receivedData.rotation
		data.bounced = receivedData.bounced
		data.bounceTimer = receivedData.bounceTimer
		data.reverseTimer = receivedData.reverseTimer
	end,
}

--Gotta return the library table!
return tire