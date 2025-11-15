local npcManager = require("npcManager")
local blockManager = require("blockManager")
local npcutils = require("npcs/npcutils")

local missileBill = {}

missileBill.colors = {
	0xFFFFFF, -- white
	0xA1FF5E, -- green
	0xFF6500, -- red
	0xFFF266, -- canary
	0xFF73AB, -- pink
}

missileBill.npcList = {}
missileBill.npcMap = {}

missileBill.blockList = {}
missileBill.blockMap = {}

local friendlyStates = table.map{5, 6, 208}
local spawnedNPCs = {}

local function canHurtPlayer(v)
	return (
		NPC.config[v.id].canhurt
		and not v.friendly
		and not v.isHidden
		and v:mem(0x12C, FIELD_WORD) == 0
		and v:mem(0x130, FIELD_WORD) == 0
		and not friendlyStates[v:mem(0x138, FIELD_WORD)]
	)
end

local function initSettings(s)
	s.friendly = s.friendly or false
	s.rotation = s.rotation or 120
	s.speed    = s.speed or 5
end

function missileBill.registerNPC(id)
	npcManager.registerEvent(id, missileBill, "onTickNPC", "onTickMissile")
	npcManager.registerEvent(id, missileBill, "onDrawNPC", "onDrawMissile")

	table.insert(missileBill.npcList, id)
	missileBill.npcMap[id] = true
end

function missileBill.registerBlock(id)
	blockManager.registerEvent(id, missileBill, "onTickEndBlock", "onTickEndArea")
	table.insert(missileBill.blockList, id)
	missileBill.blockMap[id] = true
end

function missileBill.onInitAPI()
	registerEvent(missileBill, "onDraw")
end

function missileBill.onTickEndArea(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local settings = data._settings
	local config = Block.config[v.id]

	initSettings(settings)

	if not data.initialized then
		data.initialized = true
		data.shootTimer = 0
	end

	-- a player is inside it
	if #Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) > 0 then
		if data.shootTimer % config.spawnInterval == 0 then
			local count = math.ceil(v.width/config.spawnGap) + 1
			local offset = RNG.randomInt(1, count)
			
			local n = NPC.spawn(config.missileID, v.x + offset * (v.width/count), v.y, v.section, false, true)
			n.y = n.y - math.max(n.width, n.height) - (math.floor(n.height/3) * RNG.randomInt(0, 3))

			n.data._settings.friendly = settings.friendly
			n.data._settings.rotation = settings.rotation
			n.data._settings.speed    = settings.speed
		end

		data.shootTimer = data.shootTimer + 1
	else
		data.shootTimer = 0
	end
end

function missileBill.onTickMissile(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = data._settings
	local config = NPC.config[v.id]

	if v.despawnTimer <= 0 then
		return
	end

	initSettings(settings)

	if not data.initialized then
		data.initialized = true
		data.frameX = 0
		data.rotation = (data.rotation or settings.rotation)
		data.collider = Colliders.Rect(0, 0, v.width, v.height, data.rotation)
		data.sparkEmiter = Particles.Emitter(0, 0, config.sparkParticleFile)
		data.smokeEmiter = Particles.Emitter(0, 0, config.smokeParticleFile)

		data.lineField = Particles.LineField(0, 0, 0, 0, v.width/2, 2000)
		data.lineField:addEmitter(data.sparkEmiter, false)

		data.startPoint = vector(0, 0)
		data.endPoint = vector(0, 0)
		data.timer = 0

		data.smokeEmiter:setParam("col", Color.fromHexRGB(RNG.irandomEntry(missileBill.colors)))

		local d = vector.up2:rotate(data.rotation - 90)
		
		data.speedX = d.x * settings.speed
        data.speedY = d.y * -settings.speed

		if data.speedX ~= 0 then
			v.direction = math.sign(data.speedX)
		elseif data.speedY ~= 0 then
			v.direction = math.sign(data.speedY)
		else
			v.direction = 1
		end

		table.insert(spawnedNPCs, v)
	end

	-- since there's no collision, this method of bypassing the speed cap is safe
	v.x = v.x + data.speedX
	v.y = v.y + data.speedY

	data.timer = data.timer + 1

	local dir = vector(data.speedX, data.speedY):normalize()
    data.rotation = math.deg(math.atan2(dir.y, dir.x)) - 90

	local xcen = v.x + v.width/2
	local ycen = v.y + v.height/2

	data.startPoint = vector(xcen - v.height/2, ycen)
	data.endPoint = vector(xcen + v.height/2, ycen)

	local p = (data.startPoint + data.endPoint)/2
	data.startPoint = (data.startPoint - p):rotate(data.rotation - 90) + p
	data.endPoint = (data.endPoint - p):rotate(data.rotation - 90) + p

	data.lineField.x1 = data.startPoint.x
	data.lineField.y1 = data.startPoint.y
	data.lineField.x2 = data.endPoint.x
	data.lineField.y2 = data.endPoint.y

	local randomPoint = data.startPoint + RNG.random() * (data.endPoint - data.startPoint)

	data.sparkEmiter.x = randomPoint.x
    data.sparkEmiter.y = randomPoint.y

	data.smokeEmiter.x = data.endPoint.x
	data.smokeEmiter.y = data.endPoint.y

	data.collider.rotation = data.rotation
	data.collider.width = v.width
	data.collider.height = v.height
	data.collider.x = xcen
	data.collider.y = ycen

	if data.timer % 4 == 0 then
		data.smokeEmiter:Emit(1)
	end

	if v:mem(0x12C, FIELD_WORD) > 0  --Grabbed
	or v:mem(0x136, FIELD_BOOL)      --Thrown
	or v:mem(0x138, FIELD_WORD) > 0  --Contained within
	then
		return
	end

	for k, p in ipairs(Player.get()) do
		if Colliders.collide(p, data.collider) and canHurtPlayer(v) then
			p:harm()
		end
	end
end

function missileBill.onDrawMissile(v)
	local data = v.data
	local config = NPC.config[v.id]
	local gfxW, gfxH = config.gfxwidth, config.gfxheight

	if not data.initialized then return end

	if (not v.isHidden) and (v.despawnTimer > 0) then
		data.sparkEmiter:Draw(-44)

		Graphics.drawBox{
			texture      = Graphics.sprites.npc[v.id].img,
			x            = v.x + v.width/2,
			y            = v.y + v.height/2,
			sourceX      = data.frameX * gfxW,
			sourceY      = v.animationFrame * gfxH,
			sourceWidth  = gfxW,
			sourceHeight = gfxH,
			width        = gfxW * v.direction,
			height       = gfxH,
			priority     = config.priority,
			rotation     = data.rotation,
			sceneCoords  = true,
			centered     = true,
		}
	end

	npcutils.hideNPC(v)
end

function missileBill.onDraw()
	for k = #spawnedNPCs, 1, -1 do
		local v = spawnedNPCs[k]

		if v.data.smokeEmiter:count() > 0 then
			v.data.smokeEmiter:Draw(-46, true)
		elseif not v.isValid then
			table.remove(spawnedNPCs, k)
		end
	end
end

return missileBill