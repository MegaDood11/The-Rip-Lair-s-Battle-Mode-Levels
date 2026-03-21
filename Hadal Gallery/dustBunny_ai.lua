--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local dustBunny = {}



dustBunny.sharedSettings = {
    gfxoffsetx = 0,
    gfxoffsety = 0,

	width = 28,
	height = 28,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

    ignorethrownnpcs = true,
    staticdirection = true,
}


dustBunny.idList = {}
dustBunny.idMap  = {}

dustBunny.idData = {}


-- Graphics stuff/settings setup
dustBunny.bodyImage = Graphics.loadImageResolved("dustBunny_body.png")
dustBunny.bodyFillImage = Graphics.loadImageResolved("dustBunny_bodyFill.png")
dustBunny.bodyFrames = 3
dustBunny.bodyFrameDelay = 224
dustBunny.bodyUpdateSpeedMin = 0.75
dustBunny.bodyUpdateSpeedMax = 1.25
dustBunny.bodyPerlinScrollSpeedMax = 0.0005
dustBunny.bodyPixelSize = 2

dustBunny.outlineColors = Graphics.loadImageResolved("dustBunny_outlineColors.png")
dustBunny.outlineThickness = 2
dustBunny.outlinePixelSize = 2
dustBunny.outlineScrollSpeed = vector(0.25,0.5)

dustBunny.eyesImage = Graphics.loadImageResolved("dustBunny_eyes.png")
dustBunny.eyeTypeCount = 3
dustBunny.eyeOffsetX = 6
dustBunny.eyeOffsetY = -8
dustBunny.eyeBlinkTimeMin = 128
dustBunny.eyeBlinkTimeMax = 192
dustBunny.eyeBlinkDuration = 4

dustBunny.trailPath = Misc.resolveFile("dustBunny_trail.ini")
dustBunny.trailRate = 14

dustBunny.priority = -46


dustBunny.bodyBuffer = Graphics.CaptureBuffer()
dustBunny.hasDrawnToBodyBuffer = false


dustBunny.globalTimer = 0


local bodyShader = Shader()
bodyShader:compileFromFile(nil,"dustBunny_body.frag")

local outlineShader -- compiled later 'cause macros



function dustBunny.register(npcID,getPositionFunc,getBoundingBoxFunc,updateFunc,getRandomEyeFunc)
    npcManager.registerEvent(npcID, dustBunny, "onTickNPC")
    npcManager.registerEvent(npcID, dustBunny, "onCameraDrawNPC")
    npcManager.registerEvent(npcID, dustBunny, "onDrawNPC")

    table.insert(dustBunny.idList,npcID)
    dustBunny.idMap[npcID] = true

    dustBunny.idData[npcID] = {
        getPositionFunc = getPositionFunc,
        getBoundingBoxFunc = getBoundingBoxFunc,
        updateFunc = updateFunc,
        getRandomEyeFunc = getRandomEyeFunc,
    }
end


local function applyPositionFunc(v,data,config,settings,time)
    local idData = dustBunny.idData[v.id]

    if idData.getPositionFunc ~= nil then
        local x,y,eyeRotation,eyeDistance = idData.getPositionFunc(v,data,config,settings,time)

        local newX = v.spawnX + v.spawnWidth *0.5 - v.width *0.5 + (x or 0)
        local newY = v.spawnY + v.spawnHeight*0.5 - v.height*0.5 + (y or 0)

        -- Update speed
        v.speedX = newX - v.x
        v.speedY = newY - v.y

        -- """"Fix"""" terminal velocity things
        local predictedSpeedY = math.min(8,v.speedY)
        v.y = v.y + v.speedY - predictedSpeedY


        data.totalSpeedX = data.totalSpeedX + v.speedX
        data.totalSpeedY = data.totalSpeedY + v.speedY


        if eyeRotation ~= nil then
            data.eyeRotation = eyeRotation
        elseif data.totalSpeedX ~= 0 or data.totalSpeedY ~= 0 then
            data.eyeRotation = math.deg(math.atan2(v.speedY,v.speedX)) + 90
        end
        
        data.eyeDistance = eyeDistance or 1
    end
end


local function initialisePreSpawnStuff(v)
    local idData = dustBunny.idData[v.id]

    local config = NPC.config[v.id]
    local data = v.data

    local settings = v.data._settings

    if idData.getBoundingBoxFunc ~= nil then
        local x1,y1,x2,y2 = idData.getBoundingBoxFunc(v,data,config,settings)

        local spawnX = v.spawnX + v.spawnWidth*0.5
        local spawnY = v.spawnY + v.spawnHeight*0.5

        data.spawnMinX = spawnX + x1
        data.spawnMaxX = spawnX + x2
        data.spawnMinY = spawnY + y1
        data.spawnMaxY = spawnY + y2
    else
        data.spawnMinX = v.spawnX
        data.spawnMaxX = v.spawnX + v.spawnWidth
        data.spawnMinY = v.spawnY
        data.spawnMaxY = v.spawnY + v.spawnHeight
    end

    data.layerObj = v.layerObj

    data.initializedPreSpawn = true
end


local function initialise(v,data,config,settings)
    if not data.initialisePreSpawnStuff then
        initialisePreSpawnStuff(v)
    end

    local idData = dustBunny.idData[v.id]


    -- Aesthetic stuff
    data.bodyAnimationTimer = RNG.randomInt(0,dustBunny.bodyFrames*dustBunny.bodyFrameDelay - 1)
    data.bodyPerlinOffset = vector(RNG.random(),RNG.random())
    data.bodyPerlinSpeed = vector(
        RNG.random(-dustBunny.bodyPerlinScrollSpeedMax,dustBunny.bodyPerlinScrollSpeedMax),
        RNG.random(-dustBunny.bodyPerlinScrollSpeedMax,dustBunny.bodyPerlinScrollSpeedMax)
    )

    data.eyeType = settings.eyeType
    if data.eyeType > 0 then
        data.eyeType = data.eyeType - 1
    elseif idData.getRandomEyeFunc ~= nil then
        data.eyeType = idData.getRandomEyeFunc(v,data,config,settings)
    else
        data.eyeType = RNG.randomInt(1,dustBunny.eyeTypeCount)
    end

    data.eyeRotation = 0
    data.eyeDistance = 1

    data.storedEyeRotation = nil -- used by stationary ones

    data.blinkTimer = RNG.randomInt(dustBunny.eyeBlinkTimeMin,dustBunny.eyeBlinkTimeMax)

    data.trailEmitter = Particles.Emitter(0,0,dustBunny.trailPath)
    data.trailEmitter.enabled = false
    data.trailEmitter:attach(v)

    -- Actual important stuff
    data.movementTimer = 0

    data.totalSpeedX = 0
    data.totalSpeedY = 0


    if settings.useLocalTimer then
        applyPositionFunc(v,data,config,settings,data.movementTimer)
    else
        applyPositionFunc(v,data,config,settings,dustBunny.globalTimer)
    end


    data.initialized = true
end


function dustBunny.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

    if not data.initialisePreSpawnStuff then
        initialisePreSpawnStuff(v)
    end
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

    local config = NPC.config[v.id]
    local settings = v.data._settings

    local idData = dustBunny.idData[v.id]

	if not data.initialized then
		initialise(v,data,config,settings)
	end


    data.totalSpeedX = 0
    data.totalSpeedY = 0


    -- Layer movement
    if data.layerObj ~= nil and not data.layerObj:isPaused() then
        local speedX,speedY = data.layerObj.speedX,data.layerObj.speedY

        v.x = v.x + speedX
        v.y = v.y + speedY

        data.spawnMinX = data.spawnMinX + speedX
        data.spawnMaxX = data.spawnMaxX + speedX
        data.spawnMinY = data.spawnMinY + speedY
        data.spawnMinY = data.spawnMinY + speedY

        data.totalSpeedX = data.totalSpeedX + speedX
        data.totalSpeedY = data.totalSpeedY + speedY
    end


    -- Movement
    if settings.useLocalTimer then
        data.movementTimer = data.movementTimer + 1
        applyPositionFunc(v,data,config,settings,data.movementTimer)
    else
        applyPositionFunc(v,data,config,settings,dustBunny.globalTimer)
    end


    if idData.updateFunc ~= nil then
        idData.updateFunc(v,data,config,settings)
    end


    -- Animation stuff
	data.bodyAnimationTimer = data.bodyAnimationTimer + RNG.random(dustBunny.bodyUpdateSpeedMin,dustBunny.bodyUpdateSpeedMax)

    data.blinkTimer = data.blinkTimer - 1
    if data.blinkTimer <= -dustBunny.eyeBlinkDuration then
        data.blinkTimer = RNG.randomInt(dustBunny.eyeBlinkTimeMin,dustBunny.eyeBlinkTimeMax)
    end
end


function dustBunny.onCameraDrawNPC(v,camIdx)
    if v.isHidden then return end

    local c = Camera(camIdx)
    local data = v.data

    if not data.initialisePreSpawnStuff then
        initialisePreSpawnStuff(v)
    end


    -- Handle spawning
    if c.x+c.width > data.spawnMinX and c.y+c.height > data.spawnMinY and data.spawnMaxX > c.x and data.spawnMaxY > c.y then
		-- On camera, so activate (based on this  https://github.com/smbx/smbx-legacy-source/blob/master/modGraphics.bas#L517)
		local resetOffset = (0x126 + (camIdx - 1)*2)

		if v:mem(resetOffset, FIELD_BOOL) or v:mem(0x124,FIELD_BOOL) then
			if not v:mem(0x124,FIELD_BOOL) then
				v:mem(0x14C,FIELD_WORD,camIdx)
			end

			v.despawnTimer = 180
			v:mem(0x124,FIELD_BOOL,true)
		end

		v:mem(0x126,FIELD_BOOL,false)
		v:mem(0x128,FIELD_BOOL,false)
	end

    --[[Graphics.drawBox{
        color = Color.red.. 0.2,sceneCoords = true,x = data.spawnMinX,y = data.spawnMinY,
        width = data.spawnMaxX - data.spawnMinX,height = data.spawnMaxY - data.spawnMinY,
    }]]


    if v.despawnTimer <= 0 then
        return
    end


    local config = NPC.config[v.id]
    local settings = v.data._settings

    if not data.initialized then
        initialise(v,data,config,settings)
    end


    if data.bodySprite == nil then
        data.bodySprite = Sprite{texture = dustBunny.bodyImage,frames = dustBunny.bodyFrames,pivot = Sprite.align.CENTRE}

        data.eyeSprites = {}

        for i = 1,2 do
            local sprite = Sprite{texture = dustBunny.eyesImage,frames = dustBunny.eyeTypeCount,pivot = Sprite.align.CENTRE}

            sprite.transform:setParent(data.bodySprite.transform)

            data.eyeSprites[i] = sprite
        end
    end


    -- Draw the body
    local width = dustBunny.bodyImage.width
    local height = dustBunny.bodyImage.height / dustBunny.bodyFrames

    data.bodySprite.x = v.x + v.width*0.5 + config.gfxoffsetx
    data.bodySprite.y = v.y + v.height - height*0.5 + config.gfxoffsety

    data.bodySprite:draw{
        priority = dustBunny.priority,target = dustBunny.bodyBuffer,
        sceneCoords = true,
        shader = bodyShader,uniforms = {
            timer = data.bodyAnimationTimer,
            frames = dustBunny.bodyFrames,
            frameDelay = dustBunny.bodyFrameDelay,

            perlinOffset = data.bodyPerlinOffset + data.bodyPerlinSpeed*data.bodyAnimationTimer,
            
            pixelSize = vector(dustBunny.bodyPixelSize/dustBunny.bodyImage.width,dustBunny.bodyPixelSize/dustBunny.bodyImage.height),

            perlinTexture = Graphics.sprites.hardcoded["53-1"].img,
        },
    }

    -- Draw the eyes
    if data.blinkTimer > 0 and data.eyeType > 0 then
        for i,eyeSprite in ipairs(data.eyeSprites) do
            local direction = (i - 1)*2 - 1

            --eyeSprite.rotation = data.eyeRotation
            eyeSprite.position = vector(dustBunny.eyeOffsetX*direction,dustBunny.eyeOffsetY*data.eyeDistance):rotate(data.eyeRotation)

            eyeSprite:draw{frame = data.eyeType,priority = dustBunny.priority+0.01,sceneCoords = true}
        end
    end


    dustBunny.hasDrawnToBodyBuffer = true
end


function dustBunny.onDrawNPC(v)
    if v.despawnTimer <= 0 or v.isHidden then return end

    local config = NPC.config[v.id]
    local data = v.data

    local settings = v.data._settings

    if not data.initialized then
		initialise(v,data,config,settings)
	end


    -- Handle particle emitter (has to be in onDrawNPC rather than onCameraDrawNPC)
    local emitterRate = vector(data.totalSpeedX,data.totalSpeedY).length * dustBunny.trailRate

    if emitterRate > 0 then
        data.trailEmitter:setParam("rate",emitterRate)
        data.trailEmitter.enabled = true
    else
        data.trailEmitter.enabled = false
    end

    if data.trailEmitter.enabled or data.trailEmitter:count() > 0 then
        data.trailEmitter:Draw(-76,true)
    end

    --Text.print(data.trailEmitter:Count(),v.x-camera.x,v.y-camera.y-64)
end



function dustBunny.onCameraDraw(camIdx)
    if not dustBunny.hasDrawnToBodyBuffer then
        return
    end

    local c = Camera(camIdx)

    if outlineShader == nil then
        outlineShader = Shader()
        outlineShader:compileFromFile(nil,"dustBunny_outline.frag",{OUTLINE_THICKNESS = dustBunny.outlineThickness,PIXEL_SIZE = dustBunny.outlinePixelSize})
    end

    local scrollOffset = dustBunny.outlineScrollSpeed * lunatime.tick()

    scrollOffset.x = (scrollOffset.x - c.x)/dustBunny.bodyBuffer.width
    scrollOffset.y = (scrollOffset.y - c.y)/dustBunny.bodyBuffer.height

    Graphics.drawBox{
        texture = dustBunny.bodyBuffer,priority = dustBunny.priority,
        x = 0,y = 0,width = c.width,height = c.height,
        sourceX = 0,sourceY = 0,sourceWidth = c.width,sourceHeight = c.height,

        shader = outlineShader,uniforms = {
            scrollOffset = scrollOffset,
            pixelSize = vector(dustBunny.outlinePixelSize/dustBunny.bodyBuffer.width,dustBunny.outlinePixelSize/dustBunny.bodyBuffer.height),

            bufferSize = vector(dustBunny.bodyBuffer.width,dustBunny.bodyBuffer.height),

            outlineColors = dustBunny.outlineColors,
            perlinTexture = Graphics.sprites.hardcoded["53-1"].img,
        },
    }

    dustBunny.bodyBuffer:clear(dustBunny.priority)
    dustBunny.hasDrawnToBodyBuffer = false
end


function dustBunny.onTick()
    if not Defines.levelFreeze then
        dustBunny.globalTimer = dustBunny.globalTimer + 1
    end
end

function dustBunny.onFramebufferResize(width,height)
    dustBunny.bodyBuffer = Graphics.CaptureBuffer()
end


function dustBunny.onInitAPI()
    registerEvent(dustBunny,"onCameraDraw","onCameraDraw",false)
    registerEvent(dustBunny,"onTick")
    registerEvent(dustBunny,"onFramebufferResize")
end


return dustBunny