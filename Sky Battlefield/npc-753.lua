--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local accordionBridge = {}
local npcID = NPC_ID

local defaultBlockID = (npcID)

local accordionBridgeSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	notcointransformable = true,
	ignorethrownpcs = true,

	defaultBlockID = defaultBlockID,
}

npcManager.setNpcSettings(accordionBridgeSettings)
npcManager.registerHarmTypes(npcID,{},{})

function accordionBridge.onInitAPI()
	npcManager.registerEvent(npcID, accordionBridge, "onTickNPC")
	npcManager.registerEvent(npcID, accordionBridge, "onCameraDrawNPC")
end


--local NPC_STRUCT_SIZE = 0x158
--local NPC_ADDR = readmem(0x00B259E8, FIELD_DWORD) + 128*NPC_STRUCT_SIZE


local STATE_STAY_IN = 0
local STATE_EXTEND = 1
local STATE_STAY_OUT = 2
local STATE_RETRACT = 3


local function getBlockPosition(v,data,config,settings, i,width,height)
	local r = math.rad(data.rotation)
	local c = math.cos(r)
	local s = math.sin(r)
	local absC = math.abs(c)
	local absS = math.abs(s)

	if absC > 0.01 and absS > 0.01 then
		if math.abs(absC - absS) < 0.01 then
			c = math.sign(c)
			s = math.sign(s)
		elseif absC > absS then
			c = math.sign(c)
		else
			s = math.sign(s)
		end
	end

	local x = v.x + v.width *0.5 + c*i*(settings.blockGap + width )*data.extendedness - width *0.5
	local y = v.y + v.height*0.5 + s*i*(settings.blockGap + height)*data.extendedness - height*0.5

	return x,y
end

local function initialisePreSpawn(v,data)

end

local function initialise(v,data,config,settings)
	if settings.startExtended then
		data.state = STATE_STAY_OUT
		data.extendedness = 1
	else
		data.state = STATE_STAY_IN
		data.extendedness = 0
	end

	data.rotation = settings.startRotation

	data.timer = 0

	-- Spawn blocks
	data.blockID = settings.blockID
	if data.blockID == 0 then
		data.blockID = config.defaultBlockID
	end

	data.blockIndexMin = settings.amountLeft
	data.blockIndexMax = settings.amountRight
	data.blocks = {}
	data.blockMap = {}

	for i = -data.blockIndexMin,data.blockIndexMax do
		local blockConfig = Block.config[data.blockID]
		local x,y = getBlockPosition(v,data,config,settings, i,blockConfig.width,blockConfig.height)

		local b = Block.spawn(data.blockID,x,y)

		data.blocks[i] = b
		data.blockMap[b] = true
	end

	data.initialized = true
end

local function deinitialise(v,data)
	for i = -data.blockIndexMin,data.blockIndexMax do
		local b = data.blocks[i]

		if b.isValid then
			b:delete()
		end

		data.blockMap[b] = false
		data.blocks[i] = nil
	end

	data.initialized = false
end


local function updateState(v,data,config,settings)
	data.timer = data.timer + 1

	if data.state == STATE_STAY_IN then
		if data.timer >= settings.waitDuration then
			data.state = STATE_EXTEND
			data.timer = 0
		end
	elseif data.state == STATE_EXTEND then
		data.extendedness = math.min(1,data.timer/settings.moveDuration)

		if data.extendedness >= 1 then
			data.state = STATE_STAY_OUT
			data.timer = 0
		end
	elseif data.state == STATE_STAY_OUT then
		if data.timer >= settings.waitDuration then
			data.state = STATE_RETRACT
			data.timer = 0
		end
	elseif data.state == STATE_RETRACT then
		data.extendedness = math.max(0,1 - data.timer/settings.moveDuration)

		if data.extendedness <= 0 then
			data.state = STATE_STAY_IN
			data.timer = 0

			data.rotation = data.rotation + settings.rotationChange
		end
	end
end


local function handleObjectPush(b,config,n,distanceX)
	if type(n) == "Player" then
		if n.forcedState ~= FORCEDSTATE_NONE or n.deathTimer > 0 or n:mem(0x13C,FIELD_BOOL) or n.noblockcollision then
			return
		end

		if config.playerfilter < 0 or config.playerfilter == n.character then
			return
		end
	else
		if n:mem(0x138,FIELD_WORD) ~= 0 or n:mem(0x12C,FIELD_WORD) ~= 0 or n.noblockcollision then
			return
		end

		if config.npcfilter < 0 or config.npcfilter == n.id then
			return
		end

		local config = NPC.config[n.id]

		if config.noblockcollision then
			return
		end

		if n.collisionGroup ~= "" and n.collisionGroup == b.collisionGroup then
			return
		end
	end

	if not Misc.groupsCollide[b.collisionGroup][n.collisionGroup] then
		return
	end

	if distanceX > 0 then
		if n.x-n.speedX < b.x+b.width-distanceX then
			return
		end

		n.x = b.x + b.width + distanceX
	else
		if n.x+n.width-n.speedX > b.x-distanceX then
			return
		end

		n.x = b.x - n.width + distanceX
	end

	if type(n) == "Player" then
		if distanceX > 0 then
			n:mem(0x148,FIELD_WORD,2)
		else
			n:mem(0x14C,FIELD_WORD,2)
		end

		n:mem(0x14E,FIELD_WORD,2)
	else
		if distanceX > 0 then
			n:mem(0x0C,FIELD_WORD,2)
		else
			n:mem(0x10,FIELD_WORD,2)
		end

		n:mem(0x12,FIELD_WORD,2)
	end

	if math.sign(n.speedX) ~= math.sign(distanceX) then
		n.speedX = 0
	end
end

local function pushStuffOutOfTheWay(b,distanceX) -- good function name
	local config = Block.config[b.id]

	if config.passthrough or config.semisolid or config.sizeable or config.floorslope ~= 0 or config.ceilingslope ~= 0 then
		return
	end

	local y1 = b.y
	local y2 = y1 + b.height
	local x1,x2

	if distanceX > 0 then
		x1 = b.x + b.width
		x2 = x1 + distanceX
	else
		x2 = b.x
		x1 = x2 + distanceX
	end

	--Colliders.Box(x1,y1,x2 - x1,y2 - y1):draw()

	for _,p in ipairs(Player.getIntersecting(x1,y1,x2,y2)) do
		handleObjectPush(b,config,p,distanceX)
	end

	for _,n in NPC.iterateIntersecting(x1,y1,x2,y2) do
		if n.despawnTimer > 0 and not n.isGenerator then
			handleObjectPush(b,config,n,distanceX)
		end
	end
end


function accordionBridge.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		if data.initialized then
			deinitialise(v,data)
		end

		return
	end

	local settings = v.data._settings
	local config = NPC.config[v.id]

	if not data.initialized then
		initialise(v,data,config,settings)
	end


	local layerSpeedX,layerSpeedY = 0,0
	local layerObj = v.layerObj

	if layerObj ~= nil and not layerObj:isPaused() then
		layerSpeedX = layerObj.speedX
		layerSpeedY = layerObj.speedY
		v.x = v.x + layerSpeedX
		v.y = v.y + layerSpeedY
	end

	if not Layer.isPaused() then
		updateState(v,data,config,settings)
	end

	v.speedX = 0
	v.speedY = 0


	for i = -data.blockIndexMin,data.blockIndexMax do
		local b = data.blocks[i]

		if b.isValid then
			local x,y = getBlockPosition(v,data,config,settings, i,b.width,b.height)
			local differenceX = (x - b.x)
			local differenceY = (y - b.y)

			b:translate(differenceX,differenceY)

			b.extraSpeedX = layerSpeedX
			b.extraSpeedY = layerSpeedY + differenceY


			local pushDistance = (differenceX - layerSpeedX)

			if pushDistance ~= 0 then
				pushStuffOutOfTheWay(b,pushDistance)
			end

			-- Helps with collision a little
			if b.extraSpeedX == 0 then
				b.extraSpeedX = 0.001
			end
			if b.extraSpeedY == 0 then
				b.extraSpeedY = 0.001
			end
		end
	end
end


function accordionBridge.onCameraDrawNPC(v,camIdx)

end


return accordionBridge