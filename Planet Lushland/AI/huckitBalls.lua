local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local huckitBalls = {}
local npcIDs = {}
local sprite

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

function huckitBalls.register(id)
	npcManager.registerEvent(id, huckitBalls, "onTickEndNPC")
	npcManager.registerEvent(id, huckitBalls, "onDrawNPC")
	npcIDs[id] = true
end

function huckitBalls.onTickEndNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	v.animationFrame = 0
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.rotation = nil
		return
	end

	if not data.rotation then
		data.rotation = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then data.rotation = 0 return end
	
	data.rotation = ((data.rotation or 0) + math.deg((v.speedX*config.speed)/((v.width+v.height)/4)))
	
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		v:kill(HARM_TYPE_JUMP)
		p:harm()
	end
	
	if v.ai1 == 0 then
		v.noblockcollision = true
		
		if v.ai2 == 0 then
			v.speedY = -Defines.npc_grav
		else
			v.speedY = v.ai2
		end
		
		local tbl = Block.SOLID .. Block.PLAYER
		collidingBlocks = Colliders.getColliding {
			a = v,
			b = tbl,
			btype = Colliders.BLOCK
		}

		if #collidingBlocks > 0 then --Not colliding with something
			v:kill()
		end
		
	else
		if v.collidesBlockBottom then
			v.speedY = -4.5
		end
		if v.collidesBlockLeft or v.collidesBlockRight then
			v:kill()
		end
	end
end

function huckitBalls.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

return huckitBalls