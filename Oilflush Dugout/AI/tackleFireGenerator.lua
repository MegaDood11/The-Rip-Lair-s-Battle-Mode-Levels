--[[
	by Marioman2007
]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local fireGenerator = {}

fireGenerator.idList = {}
fireGenerator.idMap = {}

fireGenerator.idListProjectile = {}
fireGenerator.idMapProjectile = {}

fireGenerator.DIR_UP    = vector( 0, -1)
fireGenerator.DIR_DOWN  = vector( 0,  1)
fireGenerator.DIR_LEFT  = vector(-1,  0)
fireGenerator.DIR_RIGHT = vector( 1,  0)


local function getJumpSpeed(distanceX, distanceY, jumpHeight, grav)
    distanceX = distanceX or 0
    distanceY = distanceY or 0
    jumpHeight = jumpHeight or 0
    grav = grav or Defines.npc_grav

	if -distanceY >= jumpHeight then
		jumpHeight = jumpHeight + (-distanceY)
	end

    local speedY = -math.sqrt(2 * grav * jumpHeight)
    local speedX = distanceX / ((-speedY + math.sqrt(speedY * speedY + 2 * grav * distanceY)) / grav)

    return speedX, speedY
end

local function setActive(v, data, settings, config)
	data.active = true
	data.waitTimer = settings.waitTime + config.warnTime
	data.shootCount = 0

	local b = data.partner
	b.data.active = false
end

local function initialize(v, data, settings, config)
	data.initialized = true
	data.waitTimer = 0
	data.shootDelay = 0
	data.shootCount = 0
	data.active = false
	data.frame = 0
	data.resetTimer = 0

	settings.idx = settings.idx or 0
	settings.distance = settings.distance or 3
	settings.waitTime = settings.waitTime or 32
	settings.shootsFirst = settings.shootsFirst or false
	settings.count = settings.count or 4

	if data.partner == nil then
		for k, b in Block.iterate(v.id) do
			if b ~= v and b.data._settings.idx == settings.idx then
				data.partner = b
				b.data.partner = v

				if settings.shootsFirst then
					b.data._settings.shootsFirst = false
				elseif not b.data._settings.shootsFirst then
					settings.shootsFirst = true
					b.data._settings.shootsFirst = false
				end

				break
			end
		end
	end

	if settings.shootsFirst then
		setActive(v, data, settings, config)
	end
end

function fireGenerator.register(id, dir)
	blockManager.registerEvent(id, fireGenerator, "onTickEndBlock")
	blockManager.registerEvent(id, fireGenerator, "onStartBlock")
	blockManager.registerEvent(id, fireGenerator, "onCameraDrawBlock")

	table.insert(fireGenerator.idList, id)
	fireGenerator.idMap[id] = dir
end

function fireGenerator.onInitAPI()
	registerEvent(fireGenerator, "onDraw")
end

function fireGenerator.onDraw()
	for _, id in ipairs(fireGenerator.idList) do
		blockutils.setBlockFrame(id, -999)
	end
end

function fireGenerator.onStartBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end

	initialize(v, v.data, v.data._settings, Block.config[v.id])
end

function fireGenerator.onTickEndBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end

	local data = v.data
	local settings = data._settings
	local config = Block.config[v.id]

	if not data.initialized then
		initialize(v, data, settings, config)
	end

	local typ = fireGenerator.idMap[v.id]
	local b = data.partner

	local thisVisible = blockutils.visible(camera, v.x, v.y, v.width, v.height)
	local partnerVisible = blockutils.visible(camera, b.x, b.y, b.width, b.height)

	if not thisVisible and not partnerVisible then
		if settings.shootsFirst then
			setActive(v, data, settings, config)
		end

		return
	end

	data.frame = 0

	if not data.active then
		return
	end

	data.waitTimer = math.max(data.waitTimer - 1, 0)
	data.shootDelay = math.max(data.shootDelay - 1, 0)

	if data.waitTimer == 0 then
		data.frame = 2
	elseif data.waitTimer < config.warnTime then
		data.frame = 1
	end

	if data.waitTimer == 0 and data.shootDelay == 0 and data.shootCount < settings.count then
		local n = NPC.spawn(
			config.projectileID,
			v.x + v.width/2,
			v.y + v.height/2,
			blockutils.getBlockSection(v),
			false, true
		)

		n.data.initial = v
		n.data.final = b
		n.data.gravForce = -typ
		n.animationFrame = -999

		if typ.y ~= 0 then
			local distanceX = b.x + b.width/2 - n.x - n.width/2

			n.speedX, n.speedY = getJumpSpeed(distanceX, 0, settings.distance * 32)
			n.data.maxTime = math.ceil(math.abs(distanceX/n.speedX))

			n.speedY = n.speedY * -typ.y
		else
			local distanceY = b.y + b.height/2 - n.y - n.height/2

			n.speedY, n.speedX = getJumpSpeed(distanceY, 0, settings.distance * 32)
			n.data.maxTime = math.ceil(math.abs(distanceY/n.speedY))

			n.speedX = n.speedX * -typ.x
		end

		data.shootCount = data.shootCount + 1
		data.shootDelay = config.shootDelay

		if data.shootCount >= settings.count then
			data.resetTimer = n.data.maxTime
		end
	end

	if data.resetTimer > 0 then
		data.resetTimer = data.resetTimer - 1

		if data.resetTimer == 0 then
			setActive(b, b.data, b.data._settings, config)
		end
	end
end

function fireGenerator.onCameraDrawBlock(v, camIdx)
	if (not blockutils.visible(Camera(camIdx), v.x, v.y, v.width, v.height)) or v.isHidden or v:mem(0x5A,FIELD_BOOL) then
		return
	end

	local data = v.data
	local img = Graphics.sprites.block[v.id].img

	if not data.initialized then
		initialize(v, data, data._settings, Block.config[v.id])
	end

	Graphics.drawImageToSceneWP(
		img,
		v.x,
		v.y,
		0,
		data.frame * img.height/3,
		img.width,
		img.height/3,
		-65
	)
end


function fireGenerator.registerProjectile(id)
	npcManager.registerEvent(id, fireGenerator, "onTickNPC")
	npcManager.registerEvent(id, fireGenerator, "onDrawNPC")

	table.insert(fireGenerator.idListProjectile, id)
	fireGenerator.idMapProjectile[id] = true
end

function fireGenerator.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if v.heldIndex ~= 0
	or v.isProjectile
	or v.forcedState > 0
	then
		return
	end

	if not data.final then
		v:kill(9)
		return
	end

	if not data.timer then
		data.timer = 0
	end

	local gravity = data.gravForce * Defines.npc_grav

	v.speedX = v.speedX + gravity.x
	v.speedY = v.speedY + gravity.y

	data.timer = data.timer + 1

	if data.timer >= data.maxTime then
		v:kill(9)
		return
	end

	if v.animationTimer % config.framespeed == 0 then
		local e = Effect.spawn(
			config.trailEffect,
			v.x + RNG.random(4, v.width - 4) - v.speedX,
			v.y + RNG.random(4, v.height - 4) - v.speedY
		)

		e.speedX = v.speedX * 0.15
		e.speedY = v.speedY * 0.15
	end

	--[[
	local oldSpeedX = v.speedX

	if v.speedX ~= 0 then
		v.direction = math.sign(v.speedX)
	end

	v.speedX = oldSpeedX
	]]
end

function fireGenerator.onDrawNPC(v)
	local data = v.data
	local config = NPC.config[v.id]

	if v.isHidden or v.despawnTimer <= 0 then
		return
	end

	local dir = vector(v.speedX, v.speedY):normalize()
	local rotation = math.deg(math.atan2(dir.y, dir.x)) + 90

	Graphics.drawBox{
		texture = Graphics.sprites.npc[v.id].img,
		x = v.x + v.width/2,
		y = v.y + v.height/2,
		sourceX = 0,
		sourceY = v.animationFrame * config.gfxheight,
		sourceWidth = config.gfxwidth,
		sourceHeight = config.gfxheight,
		rotation = rotation,
		priority = config.priority,
		sceneCoords = true,
		centered = true,
	}

	npcutils.hideNPC(v)
end

return fireGenerator