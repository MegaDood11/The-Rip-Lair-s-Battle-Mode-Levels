--[[

    extraBGOProperties.lua (v1.1)
    by MrDoubleA

]]

local extraBGOProperties = {}


local defaultPropertiesMap = {
    movementScript = "",

    parallaxX = 1,
    parallaxY = 1,
    pivotX = 0.5,
    pivotY = 0.5,
}
local propertiesList = table.unmap(defaultPropertiesMap)

local bgoSettings = {}


extraBGOProperties.relevantBGOs = {}
extraBGOProperties.relevantBGOsBySection = {}

extraBGOProperties.defaultIDSettings = {}
extraBGOProperties.idShaders = {}

extraBGOProperties.globalTimer = 0
extraBGOProperties.animationTimer = 0


-- Movement script system
local parseMovementScript
local runMovementFunc

do
    local movementScriptsCache = {}

    local proxyConstants = {
        toBlocks = function(pixels)
            return pixels/32
        end,
        toPixels = function(blocks)
            return blocks*32
        end,
    }

    local proxyTable = setmetatable({},{
        __index = function(t,key)
            return proxyConstants[key] or lunatime[key] or RNG[key] or math[key] or _G[key]
        end,
        __newindex = function(t,key,value)
            
        end,
    })


    function parseMovementScript(rawString)
        if movementScriptsCache[rawString] ~= nil then
            return movementScriptsCache[rawString]
        end


        local str = [[
            return function(npc,self,v, t, x,y,rotation,scaleX,scaleY,opacity,color)
                local func = function()
                    ]] .. rawString .. [[
                end

                func()
                
                return x,y,rotation,scaleX,scaleY,opacity,color
            end
        ]]

        local chunk,err = loadstring(str,str,"t",proxyTable)

        if chunk ~= nil then
            local func = chunk()

            movementScriptsCache[rawString] = func

            return func
        end
    end

    function runMovementFunc(v,data)
        local t = lunatime.toSeconds(extraBGOProperties.globalTimer)

        local x,y,rotation,scaleX,scaleY,opacity,color = data.movementFunc(v,v,v, t, data.offsetX,data.offsetY,data.rotation,data.scaleX,data.scaleY,data.opacity,data.color)

        data.offsetX = x
        data.offsetY = y
        data.rotation = rotation
        data.scaleX = scaleX
        data.scaleY = scaleY
        data.opacity = opacity
        data.color = color
    end
end


local function getSettings(v)
    return bgoSettings[v.idx]
    --return v.data._settings._global
end



function extraBGOProperties.registerID(id,settings)
    extraBGOProperties.defaultIDSettings[id] = settings
end



local function setUpSettings(v,data)
    local idSettings = extraBGOProperties.defaultIDSettings[v.id]
    local ownSettings = getSettings(v)

    for _,name in ipairs(propertiesList) do
        local defaultValue = defaultPropertiesMap[name]
        local ownValue,idValue

        if ownSettings ~= nil then
            ownValue = ownSettings[name]
        end
        if idSettings ~= nil then
            idValue = idSettings[name]
        end

        if ownValue ~= nil and ownValue ~= defaultValue then
            data[name] = ownValue
        elseif idValue ~= nil then
            data[name] = idValue
        else
            data[name] = defaultValue
        end
    end

    -- Movement
    if idSettings ~= nil then
        data.offsetX = idSettings.offsetX or 0
        data.offsetY = idSettings.offsetY or 0
        data.rotation = idSettings.rotation or 0
        data.scaleX = idSettings.scaleX or 1
        data.scaleY = idSettings.scaleY or 1
        data.opacity = idSettings.opacity or 1
        data.color = idSettings.color or Color.white
    else
        data.offsetX = 0
        data.offsetY = 0
        data.rotation = 0
        data.scaleX = 1
        data.scaleY = 1
        data.opacity = 1
        data.color = Color.white
    end
end


function extraBGOProperties.getData(v)
    local data = v.data.extraBGOProperties

    if data == nil then
        data = {}
        v.data.extraBGOProperties = data

        -- Initialise settings
        setUpSettings(v,data)

        -- Decide section
        data.section = Section.getIdxFromCoords(v.x - 256,v.y - 256,v.width + 512,v.height + 512)

        -- Set up movement script
        if data.movementScript ~= "" then
            data.movementFunc = parseMovementScript(data.movementScript)
            runMovementFunc(v,data)
        end
    end

    return data
end



local function updateBGO(v)
    local data = extraBGOProperties.getData(v)

    -- Run per-ID movement
    local idSettings = extraBGOProperties.defaultIDSettings[v.id]

    if idSettings ~= nil and idSettings.movementFunc ~= nil then
        idSettings.movementFunc(v,lunatime.toSeconds(extraBGOProperties.globalTimer))
    end

    -- Run per-BGo movement
    if data.movementFunc ~= nil then
        runMovementFunc(v,data)
    end
end



local function isRelevant(v)
    if extraBGOProperties.defaultIDSettings[v.id] ~= nil then
        return true
    end

    local settings = getSettings(v)
    if settings == nil then
        return false
    end

    for _,name in ipairs(propertiesList) do
        if settings[name] ~= nil and settings[name] ~= defaultPropertiesMap[name] then
            return true
        end
    end

    return false
end

local function addToRelevant(v)
    local data = extraBGOProperties.getData(v)

    table.insert(extraBGOProperties.relevantBGOs,v)
    table.insert(extraBGOProperties.relevantBGOsBySection[data.section],v)
end


function extraBGOProperties.onStart()
    -- Set up relevant tables
    extraBGOProperties.relevantBGOs = {}
    extraBGOProperties.relevantBGOsBySection = {}

    for i = 0,20 do
        extraBGOProperties.relevantBGOsBySection[i] = {}
    end

    -- Load in extra settings; done like this, rather than just
    -- accessing the settings normally, because there's currently
    -- a bug in how extra settings are handled for BGO's.
    local levelData = FileFormats.getLevelData()

    for index,bgoData in ipairs(levelData.bgo) do
        bgoSettings[index-1] = bgoData.meta.data["global"]
    end


    for _,v in BGO.iterate() do
        if isRelevant(v) then
            addToRelevant(v)
        end
    end
end


function extraBGOProperties.onTick()
    for _,sectionIdx in ipairs(Section.getActiveIndices()) do
        for _,v in ipairs(extraBGOProperties.relevantBGOsBySection[sectionIdx]) do
            if v.isValid then
                updateBGO(v)
            end
        end
    end

    if not Defines.levelFreeze then
        extraBGOProperties.globalTimer = extraBGOProperties.globalTimer + 1
    end
end



local hiddenBGOList = {}
local hiddenBGOMap = {}

local bgoBatches = {}
local drawnIDs = {}


local function handleBGODrawing(v,cam)
    if not hiddenBGOMap[v] then
        -- Don't render if hidden
        if v.isHidden then
            return
        end

        -- Hide actually rendering
        table.insert(hiddenBGOList,v)
        hiddenBGOMap[v] = true

        v.isHidden = true
    end

    
    local texture = Graphics.sprites.background[v.id].img
    if texture == nil then
        return
    end

    -- Find position
    local data = extraBGOProperties.getData(v)

    local width = v.width*data.scaleX
    local height = v.height*data.scaleY

    local pivotX = data.pivotX
    local pivotY = data.pivotY

    local x = v.x + data.offsetX*32 + v.width *pivotX
    local y = v.y + data.offsetY*32 + v.height*pivotY

    local rotated = (data.rotation%360 > 0)

    if data.parallaxX ~= 1 then
        x = (x - (cam.x + cam.width*0.5))*data.parallaxX + cam.width*0.5
    else
        x = x - cam.x
    end

    if data.parallaxY ~= 1 then
        y = (y - (cam.y + cam.height*0.5))*data.parallaxY + cam.height*0.5
    else
        y = y - cam.y
    end


    -- Culling
    if rotated then
        -- Improved culling code, courtesy of Hoeloe!
        local cullSize = math.sqrt(width*width + height*height)*math.max(pivotX,pivotY,1 - pivotX,1 - pivotY)

        if (x + cullSize) < 0 or (x - cullSize) > cam.width or (y + cullSize) < 0 or (y - cullSize) > cam.height then
            return
        end

        --[[Graphics.drawBox{
            color = Color.red.. 0.25,centred = true,
            x = x,y = y,width = cullSize*2,height = cullSize*2,
        }]]
    else
        local cullX = x - width*pivotX
        if cullX+width < 0 or cullX > cam.width then
            return
        end

        local cullY = y - height*pivotY
        if cullY+height < 0 or cullY > cam.height then
            return
        end
    end


    -- Handle the "batch"
    local batch = bgoBatches[v.id]

    if batch == nil then
        batch = {}
        bgoBatches[v.id] = batch

        batch.config = BGO.config[v.id]

        batch.vertexCoords = {}
        batch.textureCoords = {}
        batch.vertexColors = {}

        batch.previousVertexCounter = 0
        batch.vertexCounter = 0

        batch.previousColorCounter = 0
        batch.colorCounter = 0


        batch.inIDsTable = false

        batch.tx1 = 0
        batch.ty1 = 0
        batch.tx2 = 0
        batch.ty2 = 0

        batch.drawArgs = {vertexCoords = batch.vertexCoords,textureCoords = batch.textureCoords,vertexColors = batch.vertexColors}

        -- Shader stuff
        local idSettings = extraBGOProperties.defaultIDSettings[v.id]

        if idSettings ~= nil and (idSettings.fragShader ~= nil or idSettings.vertShader ~= nil) then
            -- Set up shader
            local shader = extraBGOProperties.idShaders[v.id]

            if shader == nil then
                shader = Shader()
                shader:compileFromFile(idSettings.vertShader,idSettings.fragShader)

                extraBGOProperties.idShaders[v.id] = shader
            end

            batch.drawArgs.shader = shader
        end
    end

    if not batch.inIDsTable then
        -- Set up properties of the draw
        batch.drawArgs.priority = batch.config.priority
        batch.drawArgs.texture = texture

        -- Set up texture coordinates (will be the same for all of the same ID)
        local frame = math.floor(extraBGOProperties.animationTimer/batch.config.framespeed) % batch.config.frames
        local width = batch.config.width
        local height = batch.config.height

        batch.tx1 = 0
        batch.ty1 = frame*height/texture.height
        batch.tx2 = batch.tx1 + width/texture.width
        batch.ty2 = batch.ty1 + height/texture.height

        -- Set up uniforms
        local idSettings = extraBGOProperties.defaultIDSettings[v.id]

        if idSettings ~= nil and idSettings.getUniformsFunc ~= nil then
            batch.drawArgs.uniforms = idSettings.getUniformsFunc(v.id,cam.idx)
        end


        table.insert(drawnIDs,v.id)
    end

    -- Add vertex coords
    local vertexCounter = batch.vertexCounter
    local vc = batch.vertexCoords

    if rotated then
        -- Rotated
        local angle = math.rad(data.rotation)
        local sn = math.sin(angle)
        local cs = math.cos(angle)

        local invPivotX = 1 - pivotX
        local invPivotY = 1 - pivotY

        vc[vertexCounter+1 ] = x + sn*height*pivotY    - cs*width*pivotX    -- top left
        vc[vertexCounter+2 ] = y - cs*height*pivotY    - sn*width*pivotX   
        vc[vertexCounter+3 ] = x + sn*height*pivotY    + cs*width*invPivotX -- top right
        vc[vertexCounter+4 ] = y - cs*height*pivotY    + sn*width*invPivotX
        vc[vertexCounter+5 ] = x - sn*height*invPivotY - cs*width*pivotX    -- bottom left
        vc[vertexCounter+6 ] = y + cs*height*invPivotY - sn*width*pivotX   
        vc[vertexCounter+11] = x - sn*height*invPivotY + cs*width*invPivotX  -- bottom right
        vc[vertexCounter+12] = y + cs*height*invPivotY + sn*width*invPivotX
    else
        -- No rotation
        local x1 = x - width*pivotX
        local y1 = y - height*pivotY
        local x2 = x1 + width
        local y2 = y1 + height

        vc[vertexCounter+1 ] = x1 -- top left
        vc[vertexCounter+2 ] = y1
        vc[vertexCounter+3 ] = x2 -- top right
        vc[vertexCounter+4 ] = y1
        vc[vertexCounter+5 ] = x1 -- bottom left
        vc[vertexCounter+6 ] = y2
        vc[vertexCounter+11] = x2  -- bottom right
        vc[vertexCounter+12] = y2
    end

    vc[vertexCounter+7 ] = vc[vertexCounter+3 ] -- top right, again
    vc[vertexCounter+8 ] = vc[vertexCounter+4 ]
    vc[vertexCounter+9 ] = vc[vertexCounter+5 ] -- bottom left, again
    vc[vertexCounter+10] = vc[vertexCounter+6 ]

    -- Add texture coords
    local tc = batch.textureCoords

    tc[vertexCounter+1 ] = batch.tx1 -- top left
    tc[vertexCounter+2 ] = batch.ty1
    tc[vertexCounter+3 ] = batch.tx2 -- top right
    tc[vertexCounter+4 ] = batch.ty1
    tc[vertexCounter+5 ] = batch.tx1 -- bottom left
    tc[vertexCounter+6 ] = batch.ty2
    tc[vertexCounter+7 ] = batch.tx2 -- top right
    tc[vertexCounter+8 ] = batch.ty1
    tc[vertexCounter+9 ] = batch.tx1 -- bottom left
    tc[vertexCounter+10] = batch.ty2
    tc[vertexCounter+11] = batch.tx2  -- bottom right
    tc[vertexCounter+12] = batch.ty2

    batch.vertexCounter = vertexCounter + 12

    -- Add vertex colors
    local colorCounter = batch.colorCounter
    local colors = batch.vertexColors

    local opacity = data.color.a*data.opacity

    for i = 1,6 do
        colors[colorCounter+1] = data.color.r*opacity
        colors[colorCounter+2] = data.color.g*opacity
        colors[colorCounter+3] = data.color.b*opacity
        colors[colorCounter+4] = opacity

        colorCounter = colorCounter + 4
    end

    batch.colorCounter = colorCounter


    --Text.print("IDX: ".. v.idx,x,y)
    --Text.print(data.parallaxX,x,y+16)
end


function extraBGOProperties.onCameraDraw(camIdx)
    local cam = Camera(camIdx)
    local sectionIdx = Player(camIdx).section

    -- Handle each BGO
    for _,v in ipairs(extraBGOProperties.relevantBGOsBySection[sectionIdx]) do
        if v.isValid then
            handleBGODrawing(v,cam)
        end
    end

    -- Draw "batches"
    for _,id in ipairs(drawnIDs) do
        local batch = bgoBatches[id]

        -- Clear out old vertices
        for i = batch.vertexCounter+1,batch.previousVertexCounter do
            batch.vertexCoords[i] = nil
            batch.textureCoords[i] = nil
        end

        for i = batch.colorCounter+1,batch.previousColorCounter do
            batch.vertexColors[i] = nil
        end

        batch.previousVertexCounter = batch.vertexCounter
        batch.vertexCounter = 0

        batch.previousColorCounter = batch.colorCounter
        batch.colorCounter = 0


        Graphics.glDraw(batch.drawArgs)

        batch.inIDsTable = false
    end

    -- Empty drawn IDs table
    local i = 1

    while (drawnIDs[i] ~= nil) do
        drawnIDs[i] = nil
        i = i + 1
    end
end

function extraBGOProperties.onDrawEnd()
    -- Undo hidden blocks
    local i = 1

    while (hiddenBGOList[i] ~= nil) do
        local v = hiddenBGOList[i]

        if v.isValid then
            v.isHidden = false
        end
        
        hiddenBGOList[i] = nil
        hiddenBGOMap[v] = nil

        i = i + 1
    end
end

function extraBGOProperties.onDraw()
    -- Update animation timer
    extraBGOProperties.animationTimer = extraBGOProperties.animationTimer + 1
end


function extraBGOProperties.onInitAPI()
    registerEvent(extraBGOProperties,"onStart")
    
    registerEvent(extraBGOProperties,"onTick")

    registerEvent(extraBGOProperties,"onCameraDraw")
    registerEvent(extraBGOProperties,"onDrawEnd")
    registerEvent(extraBGOProperties,"onDraw")
end


return extraBGOProperties