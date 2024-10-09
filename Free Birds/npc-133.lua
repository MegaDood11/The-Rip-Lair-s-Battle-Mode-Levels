local bullet = {}
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

local onlinePlayNPC = require("scripts/onlinePlay_npc")

function bullet.onTickNPC(v)
	if v.despawnTimer <= 0 then
		return
	end
	
	v.friendly = false
	
	local data = v.data

	data.lifetime = (data.lifetime or 128) - 1

	if data.lifetime <= 0 then
		Effect.spawn(10,v.x + v.width*0.5 - 16,v.y + v.height*0.5 - 16)
		onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
	end
	
	data.timer = data.timer or 0
	
	data.timer = data.timer + 1
	data.rotation = (data.timer * 7) * v.direction
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

function bullet.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(16/2)+config.gfxoffsety,
		width = 16,height = 16,

		sourceX = 0,sourceY = v.animationFrame*16,
		sourceWidth = 16,sourceHeight = 16,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

function bullet.onInitAPI()
	npcManager.registerEvent(npcID, bullet, "onTickNPC")
	npcManager.registerEvent(npcID, bullet, "onDrawNPC")
end

return bullet