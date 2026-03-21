--[[

	Written by MrDoubleA
	Please give credit!

	Part of MrDoubleA's NPC Pack

]]

local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local ai = require("dustBunny_ai")


local bunnyCluster = {}
local blockID = BLOCK_ID


local bunnyClusterSettings = {
	id = blockID,
	
	passthrough = true,
}

blockManager.setBlockSettings(bunnyClusterSettings)



local SCREEN_MODE_ADDR = 0x00B25130
local DYNAMIC_SCREEN_MODE_ADDR = 0x00B25132


bunnyCluster.bodyAnimationTimer = 0


-- How close to the edge of the cluster a bunny needs to be to be considered part of the "border".
local CLOSENESS_FOR_BORDER = 1
-- How close to the edge of the cluster a bunny needs to be in order to be able to stare at the player.
local CLOSENESS_FOR_STARE = 3


local function getBodySize()
	return ai.bodyImage.width,ai.bodyImage.height/ai.bodyFrames	
end

local function getRandomBunnyOffset(rngObj,settings)
	local val = rngObj:random(-settings.randomOffset,settings.randomOffset)

	val = math.floor(val/ai.bodyPixelSize + 0.5)*ai.bodyPixelSize

	return val
end

local function isCloseEnoughToBorder(data,indexX,indexY,val)
	return (indexX <= val or indexX >= data.countX-val+1 or indexY <= val or indexY >= data.countY-val+1)
end


local function createBunnies(v,data,config,settings)
	local rngObj = RNG.new(v.x + v.y*v.y)

	local bodyWidth,bodyHeight = getBodySize()

	data.countX = math.ceil(v.width /settings.horizontalGap)
	data.countY = math.ceil(v.height/settings.verticalGap  )

	data.totalWidth  = data.countX*settings.horizontalGap + (bodyWidth  - settings.horizontalGap)
	data.totalHeight = data.countY*settings.verticalGap   + (bodyHeight - settings.verticalGap  )

	data.bunnyObjs = {}

	for indexX = 1,data.countX do
		data.bunnyObjs[indexX] = {}

		for indexY = 1,data.countY do
			local obj = {}

			-- Initialise the object
			obj.offsetX = (indexX - 1)*settings.horizontalGap + getRandomBunnyOffset(rngObj,settings)
			obj.offsetY = (indexY - 1)*settings.verticalGap   + getRandomBunnyOffset(rngObj,settings)

			obj.drawBody = isCloseEnoughToBorder(data,indexX,indexY,CLOSENESS_FOR_BORDER)

			if rngObj:random(1,100) <= settings.hasEyesChance then
				obj.eyeType = rngObj:randomInt(1,ai.eyeTypeCount)
				obj.eyeRotation = rngObj:random(0,360)

				obj.blinkTimer = rngObj:randomInt(ai.eyeBlinkTimeMin,ai.eyeBlinkTimeMax)

				if isCloseEnoughToBorder(data,indexX,indexY,CLOSENESS_FOR_STARE) and rngObj:random(1,100) <= settings.canStareChance then
					obj.canStare = true
					obj.eyeStartRotation = obj.eyeRotation
				else
					obj.canStare = false
				end
			else
				obj.eyeType = 0
			end


			data.bunnyObjs[indexX][indexY] = obj
		end
	end
end


local function initialise(v,data,config,settings)
	createBunnies(v,data,config,settings)

	data.initialized = true
end

local function deinitialise(v,data,config,settings)
	data.bunnyObjs = nil -- poor garbage collector...

	data.initialized = false
end


local function isOffScreen(v)
	for _,c in ipairs(Camera.get()) do
		if (c.idx == 1 or c.isSplit or mem(SCREEN_MODE_ADDR,FIELD_WORD) == 6)
		and v.x+v.width  > c.x and v.x < c.x+c.width
		and v.y+v.height > c.y and v.y < c.y+c.height
		then
			return false
		end
	end

	return true
end


local function updateBunnyObj(v,data,config,settings,obj,closestPlayer)
	if obj.eyeType > 0 then
		obj.blinkTimer = obj.blinkTimer - 1
		if obj.blinkTimer <= -ai.eyeBlinkDuration then
			obj.blinkTimer = RNG.randomInt(ai.eyeBlinkTimeMin,ai.eyeBlinkTimeMax)
		end

		if obj.canStare then
			local width,height = getBodySize()

			local x = v.x + v.width *0.5 - data.totalWidth *0.5 + width *0.5 + obj.offsetX
			local y = v.y + v.height*0.5 - data.totalHeight*0.5 + height*0.5 + obj.offsetY

			local distance = vector(closestPlayer.x - x,closestPlayer.y - y)

			local targetRotation = obj.eyeStartRotation

			if distance.length <= settings.stareMaxPlayerDistance then
				targetRotation = math.deg(math.atan2(distance.y,distance.x)) + 90
			end

			obj.eyeRotation = math.anglelerp(obj.eyeRotation,targetRotation,0.0625)
		end
	end
end


function bunnyCluster.onInitAPI()
	blockManager.registerEvent(blockID,bunnyCluster,"onTickBlock")
	blockManager.registerEvent(blockID,bunnyCluster,"onCameraDrawBlock")
	blockManager.registerEvent(blockID,bunnyCluster,"onCollideBlock")

	registerEvent(bunnyCluster,"onCameraDraw","onCameraDraw",false)
	registerEvent(bunnyCluster,"onTick")
end


function bunnyCluster.onCollideBlock(v,n)
	if type(n) == "Player" then
		n:harm()
	end
end


function bunnyCluster.onTickBlock(v)
	local data = v.data

	if data.despawnTimer == nil or data.despawnTimer <= 0 then
		return
	end

	local config = Block.config[v.id]
	local settings = v.data._settings

	-- Handle being despawned
	data.despawnTimer = data.despawnTimer - 1
	if data.despawnTimer <= 0 then
		if data.initialized then
			deinitialise(v,data,config,settings)
		end

		return
	end


	local closestPlayer = Player.getNearest(v.x + v.width*0.5,v.y + v.height*0.5)

	for indexX = 1,data.countX do
		for indexY = 1,data.countY do
			local obj = data.bunnyObjs[indexX][indexY]

			updateBunnyObj(v,data,configs,settings,obj,closestPlayer)
		end
	end
end


local bodyGlDrawArgs = {vertexCoords = {},textureCoords = {},sceneCoords = true}
local bodyVertexCount = 0
local bodyOldVertexCount = 0

local fillGlDrawArgs = {vertexCoords = {},textureCoords = {},sceneCoords = true}
local fillVertexCount = 0
local fillOldVertexCount = 0

local eyesGlDrawArgs = {vertexCoords = {},textureCoords = {},sceneCoords = true}
local eyesVertexCount = 0
local eyesOldVertexCount = 0


local clusterShader = Shader()
clusterShader:compileFromFile(nil,"dustBunny_cluster.frag")


local drawArgsSetup = false

local function setupDrawArgs(c)
	if drawArgsSetup then
		return
	end

	bodyGlDrawArgs.texture = ai.bodyImage
	fillGlDrawArgs.texture = ai.bodyFillImage
	eyesGlDrawArgs.texture = ai.eyesImage

	bodyGlDrawArgs.priority = ai.priority - 0.02
	fillGlDrawArgs.priority = ai.priority - 0.03
	eyesGlDrawArgs.priority = ai.priority + 0.01

	bodyGlDrawArgs.target = ai.bodyBuffer
	fillGlDrawArgs.target = ai.bodyBuffer

	-- Setup body shader
	local bodyWidth,bodyHeight = getBodySize()
	local bodyUniforms = {}

	bodyUniforms.timer = bunnyCluster.bodyAnimationTimer
	bodyUniforms.frames = ai.bodyFrames
	bodyUniforms.frameDelay = ai.bodyFrameDelay

	bodyUniforms.pixelSize = ai.bodyPixelSize

	bodyUniforms.screenSize = vector(800,600)
	bodyUniforms.bodyTextureSize = vector(bodyWidth,bodyHeight)

	bodyUniforms.perlinOffset = bunnyCluster.bodyAnimationTimer*vector(ai.bodyPerlinScrollSpeedMax)*bodyUniforms.bodyTextureSize - vector(c.x,c.y)
	--bodyUniforms.perlinOffset = -vector(c.x,c.y)
	bodyUniforms.perlinTexture = Graphics.sprites.hardcoded["53-1"].img


	bodyGlDrawArgs.shader = clusterShader
	fillGlDrawArgs.shader = clusterShader

	bodyGlDrawArgs.uniforms = bodyUniforms
	fillGlDrawArgs.uniforms = bodyUniforms


	drawArgsSetup = true
end


local function addQuadToDrawArgs(args,count,x,y,width,height,sourceX,sourceY,sourceWidth,sourceHeight)
	local texture = args.texture
	local vc = args.vertexCoords
	local tc = args.textureCoords

	-- Vertex coords
	local x1 = x
	local y1 = y
	local x2 = x + width
	local y2 = y + height

	vc[count+1 ] = x1 -- top left
	vc[count+2 ] = y1
	vc[count+3 ] = x2 -- top right
	vc[count+4 ] = y1
	vc[count+5 ] = x1 -- bottom left
	vc[count+6 ] = y2
	vc[count+7 ] = x2 -- top right
	vc[count+8 ] = y1
	vc[count+9 ] = x1 -- bottom left
	vc[count+10] = y2
	vc[count+11] = x2 -- bottom right
	vc[count+12] = y2

	-- Texture coords
	local x1 = sourceX/texture.width
	local y1 = sourceY/texture.height
	local x2 = (sourceX + sourceWidth)/texture.width
	local y2 = (sourceY + sourceHeight)/texture.height

	tc[count+1 ] = x1 -- top left
	tc[count+2 ] = y1
	tc[count+3 ] = x2 -- top right
	tc[count+4 ] = y1
	tc[count+5 ] = x1 -- bottom left
	tc[count+6 ] = y2
	tc[count+7 ] = x2 -- top right
	tc[count+8 ] = y1
	tc[count+9 ] = x1 -- bottom left
	tc[count+10] = y2
	tc[count+11] = x2 -- bottom right
	tc[count+12] = y2
end


local function drawBunnyObj(v,data,config,settings,obj,totalX,totalY,c)
	-- Prepare body
	local bodyWidth,bodyHeight = getBodySize()

	local bodyX = math.floor(totalX + obj.offsetX)
	local bodyY = math.floor(totalY + obj.offsetY)

	if obj.drawBody then
		addQuadToDrawArgs(bodyGlDrawArgs,bodyVertexCount,bodyX,bodyY,bodyWidth,bodyHeight,0,0,bodyWidth,bodyHeight)

		bodyVertexCount = bodyVertexCount + 12
	end

	-- Prepare eyes
	if obj.eyeType > 0 and obj.blinkTimer > 0 then
		local eyeWidth = eyesGlDrawArgs.texture.width
		local eyeHeight = eyesGlDrawArgs.texture.height/ai.eyeTypeCount

		local eyeSourceX = 0
		local eyeSourceY = (obj.eyeType - 1)*eyeHeight

		for i = 1,2 do
			local direction = (i - 1)*2 - 1

			local position = vector(ai.eyeOffsetX*direction,ai.eyeOffsetY):rotate(obj.eyeRotation)

			local eyeX = bodyX + bodyWidth *0.5 - eyeWidth *0.5 + position.x
			local eyeY = bodyY + bodyHeight*0.5 - eyeHeight*0.5 + position.y

			addQuadToDrawArgs(eyesGlDrawArgs,eyesVertexCount,eyeX,eyeY,eyeWidth,eyeHeight,eyeSourceX,eyeSourceY,eyeWidth,eyeHeight)
			eyesVertexCount = eyesVertexCount + 12
		end
	end
end


function bunnyCluster.onCameraDrawBlock(v,camIdx)
	if v.isHidden or v:mem(0x5A,FIELD_BOOL) or isOffScreen(v) --[[or player.keys.dropItem]] then
		return
	end

	local config = Block.config[v.id]
	local data = v.data

	local settings = v.data._settings

	data.despawnTimer = 180

	if not data.initialized then
		initialise(v,data,config,settings)
	end

	--Colliders.getHitbox(v):Draw()

	local c = Camera(camIdx)

	local totalX = v.x + v.width *0.5 - data.totalWidth *0.5
	local totalY = v.y + v.height*0.5 - data.totalHeight*0.5

	local minIndexX = math.clamp(math.floor((c.x - totalX) / settings.horizontalGap)          ,1,data.countX)
	local minIndexY = math.clamp(math.floor((c.y - totalY) / settings.verticalGap  )          ,1,data.countY)
	local maxIndexX = math.clamp(math.ceil((c.x + c.width  - totalX) / settings.horizontalGap),1,data.countX)
	local maxIndexY = math.clamp(math.ceil((c.y + c.height - totalY) / settings.verticalGap  ),1,data.countY)
	

	setupDrawArgs(c)


	for indexX = minIndexX,maxIndexX do
		for indexY = minIndexY,maxIndexY do
			local obj = data.bunnyObjs[indexX][indexY]

			drawBunnyObj(v,data,config,settings,obj,totalX,totalY,c)
		end
	end

	-- Do the fill for the middle
	local bunnyWidth,bunnyHeight = getBodySize()

	local fillX = totalX + bunnyWidth*0.5
	local fillY = totalY + bunnyHeight*0.5

	local fillWidth = data.totalWidth - bunnyWidth
	local fillHeight = data.totalHeight - bunnyHeight

	local fillUnitWidth = ai.bodyFillImage.width
	local fillUnitHeight = ai.bodyFillImage.height / ai.bodyFrames

	addQuadToDrawArgs(fillGlDrawArgs,fillVertexCount,fillX,fillY,fillWidth,fillHeight,0,0,fillWidth,fillHeight)
	fillVertexCount = fillVertexCount + 12


	--Text.print(minIndexX,v.x-c.x,v.y-c.y)
	--Text.print(minIndexX,v.x+v.width-c.x,v.y-c.y)
	--Text.print(maxIndexX,v.x-c.x,v.y-c.y+32)
	--Text.print(maxIndexX,v.x+v.width-c.x,v.y-c.y+32)
end


function bunnyCluster.onCameraDraw(camIdx)
	--Text.print((bodyVertexCount + fillVertexCount + eyesVertexCount) / 12,32,32)

	if bodyVertexCount > 0 then
		-- Clear out vertices
		for i = bodyVertexCount+1,bodyOldVertexCount do
			bodyGlDrawArgs.vertexCoords[i] = nil
			bodyGlDrawArgs.textureCoords[i] = nil
		end

		Graphics.glDraw(bodyGlDrawArgs)

		bodyOldVertexCount = bodyVertexCount
		bodyVertexCount = 0

		ai.hasDrawnToBodyBuffer = true
	end

	if fillVertexCount > 0 then
		-- Clear out vertices
		for i = fillVertexCount+1,fillOldVertexCount do
			fillGlDrawArgs.vertexCoords[i] = nil
			fillGlDrawArgs.textureCoords[i] = nil
		end

		Graphics.glDraw(fillGlDrawArgs)

		fillOldVertexCount = fillVertexCount
		fillVertexCount = 0

		ai.hasDrawnToBodyBuffer = true
	end

	if eyesVertexCount > 0 then
		-- Clear out vertices
		for i = eyesVertexCount+1,eyesOldVertexCount do
			eyesGlDrawArgs.vertexCoords[i] = nil
			eyesGlDrawArgs.textureCoords[i] = nil
		end

		Graphics.glDraw(eyesGlDrawArgs)

		eyesOldVertexCount = eyesVertexCount
		eyesVertexCount = 0
	end

	drawArgsSetup = false
end


function bunnyCluster.onTick()
	if not Defines.levelFreeze then
		bunnyCluster.bodyAnimationTimer = bunnyCluster.bodyAnimationTimer + RNG.random(ai.bodyUpdateSpeedMin,ai.bodyUpdateSpeedMax)
	end
end


return bunnyCluster