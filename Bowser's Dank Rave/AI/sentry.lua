local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")

local sentry = {}

sentry.idList = {}
sentry.idMap = {}

local customExplosion = Explosion.register(48, nil, nil, true, false)

local replacementMap = {
	[0] = 0, --chase
	[1] = 4, --chase 2
	[2] = 2, --Fly & Turn Horizontal
	[3] = 3, --Fly & Turn Vertical
	[4] = 6, --Fly Horizontal
	[5] = 7, --Fly Vertical
}

local STATE = {
	IDLE = 0,
	LOCKING = 1,
	LOCKED = 2,
}

local function SFXPlay(sfx)
	if sfx and sfx.id then
		SFX.play(sfx.id, sfx.volume)
	end
end

local function createCrossHair(v, radius)
	if Level.endState() ~= LEVEL_WIN_TYPE_NONE then return end

	local x = v.data.storedX or v.x + v.width/2
	local y = v.data.storedY or v.y + v.height/2

	v.data.storedX = nil
	v.data.storedY = nil

	local t = {
		x = x,
		y = y,
		storedPos = vector(0, 0),
		goalPos = vector(0, 0),
		lerpTimer = -1,
		collider = Colliders.Circle(x, y, radius),
		warnTimer = -1,
		shineTimer = -1,
		state = STATE.IDLE,
		rotation = 0,
		opacity = 0,
		scale = 1,
		frame = 0,
		timer = 0,
		storedTime = nil,
		isValid = true,
		crossOpacity = 0,
		crossRotation = 0,
		storedRotation = 0,
	}

	return t
end

function sentry.register(id)
	if sentry.idMap[id] then return end

	local config = NPC.config[id]

	npcManager.registerEvent(id, sentry, "onTickNPC")
	npcManager.registerEvent(id, sentry, "onDrawNPC")

	table.insert(sentry.idList, id)
	sentry.idMap[id] = true
end

function sentry.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	local config = NPC.config[v.id]
	local isChaseAI = v.ai1 == 0 or v.ai1 == 4

	if v.despawnTimer <= 0 then
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = 0
		data.crossHair = nil
		data.storedX = nil
		data.storedY = nil
		data._settings.ai1 = data._settings.ai1 or 1

		v.friendly = true

	-- don't despawn if set to chase
	elseif isChaseAI or data.crossHair then
		if isChaseAI then
			v.despawnTimer = 180
		else
			v.despawnTimer = math.max(v.despawnTimer, 2)
		end

		v:mem(0x124, FIELD_BOOL, true)
	end
	
	data.timer = data.timer + 1
	v.ai1 = replacementMap[data._settings.ai1]

	if data.crossHair then
		local n = data.crossHair

		n.timer = n.timer + 1

		if n.state == STATE.IDLE then
			n.frame = math.floor(n.timer / config.crossHairFramespeed) % config.idleFrames
			n.crossOpacity = math.min(n.crossOpacity + 0.1, 1)
			n.crossRotation = (n.crossRotation + 4) % 360

			if n.lerpTimer == -1 and n.crossOpacity == 1 then
				local p = Player.getNearest(n.x, n.y)
				local disX = p.x + p.width/2 - n.x
				local disY = p.y + p.height/2 - n.y

				n.x = n.x + math.min(math.abs(disX/10), config.followSpeed) * math.sign(disX)
				n.y = n.y + math.min(math.abs(disY/10), config.followSpeed) * math.sign(disY)

				n.collider.x = n.x
				n.collider.y = n.y

				if Colliders.collide(n.collider, p) then
					n.storedPos.x = n.x
					n.storedPos.y = n.y

					n.goalPos.x = p.x + p.width/2 + p.speedX
					n.goalPos.y = p.y + p.height/2 + p.speedY

					n.lerpTimer = 0
					SFXPlay(config.targetLockedSFX)
				end
				
			elseif n.lerpTimer >= 0 then
				n.lerpTimer = math.min(n.lerpTimer + 1/config.lerpTime, 1)

				local pos = easing.outSine(n.lerpTimer, n.storedPos, n.goalPos - n.storedPos, 1)

				n.x, n.y = pos.x, pos.y

				if n.lerpTimer == 1 then
					n.lerpTimer = -1
					n.timer = 0
					n.state = STATE.LOCKING
					n.storedRotation = n.crossRotation
				end
			end

		elseif n.state == STATE.LOCKING then
			local duration = config.lockingFrames * config.crossHairFramespeed

			n.frame = math.floor(math.min(n.timer, duration - 1) / config.crossHairFramespeed) % config.lockingFrames + config.idleFrames
			n.crossRotation = easing.outSine(n.timer, n.storedRotation, -n.storedRotation, config.rotationTime)
			
			if n.timer == config.rotationTime then
				n.timer = 0
				n.state = STATE.LOCKED
			end

		elseif n.state == STATE.LOCKED then
			n.frame = math.floor(n.timer / config.crossHairFramespeed) % config.lockedFrames + config.lockingFrames + config.idleFrames

			if n.timer == config.waitTime then
				n.warnTimer = 0
			end

			if n.warnTimer >= 0 then
				n.warnTimer = n.warnTimer + 1
				n.opacity = math.min(n.opacity + 0.2, 1)

				if n.storedTime then
					n.scale = easing.inBack(n.warnTimer - n.storedTime, 1, -1, config.warnTime)
				elseif n.opacity == 1 then
					n.storedTime = n.warnTimer
				end

				if n.warnTimer == config.warnTime then
					n.warnTimer = -1
					n.opacity = 0
					n.scale = 1
					n.shineTimer = 0
					n.storedTime = nil
				end
			end

			if n.shineTimer >= 0 then
				n.shineTimer = n.shineTimer + 1
				n.opacity = math.min(n.opacity + 0.075, 1)
				n.scale = easing.inSine(n.shineTimer, 1, -1, config.shineTime)
				n.rotation = easing.outSine(n.shineTimer, 0, 360, config.shineTime)

				if n.shineTimer == config.shineTime then
					n.shineTimer = -1
					data.storedX = n.x
					data.storedY = n.y

					local e = Explosion.create(n.x, n.y, customExplosion, nil, false)

					if e then
						e.radius = config.explosionRadius
						Effect.spawn(config.explosionEffect, n.x, n.y)
						SFXPlay(config.explosionSFX)
					end
				end
			end

			if data.storedX and data.storedY then
				n.crossOpacity = math.max(n.crossOpacity - 0.2, 0)

				if n.crossOpacity == 0 then
					n.opacity = 0
					n.rotation = 0
					n.scale = 1
					n.isValid = false
					data.timer = 0
					data.crossHair = nil
				end
			end
		end

	elseif data.timer == config.delay then
		data.crossHair = createCrossHair(v, config.radius)
	end
end

function sentry.onDrawNPC(v)
	if v.isHidden or v.despawnTimer <= 0 then return end

	local data = v.data
	local config = NPC.config[v.id]

	if data.crossHair then
		local n = data.crossHair
		local img = config.crossHairImg
		local height = img.height/(config.idleFrames + config.lockingFrames + config.lockedFrames)

		Graphics.drawBox{
			texture = img,
			x = n.x, y = n.y,
			sourceY = n.frame * height,
			sourceHeight = height,
			color = Color.white..n.crossOpacity,
			priority = config.crossPriority,
			rotation = n.crossRotation,
			sceneCoords = true,
			centered = true,
		}

		if n.warnTimer >= 0 or n.shineTimer >= 0 then
			local img = config.warningImg
			local priority = config.crossPriority - 0.01

			if n.shineTimer >= 0 then
				img = config.shineImg
				priority = config.crossPriority
			end

			Graphics.drawBox{
				texture = img,
				x = n.x, y = n.y,
				width = img.width * n.scale,
				height = img.height * n.scale,
				color = Color.white..n.opacity,
				priority = priority,
				rotation = n.rotation,
				sceneCoords = true,
				centered = true,
			}
		end
	end

	npcutils.drawNPC(v, {priority = config.priority})

	if config.overlayImg then
		npcutils.drawNPC(v, {texture = config.overlayImg, priority = config.priority})
	end

	npcutils.hideNPC(v)
end

return sentry