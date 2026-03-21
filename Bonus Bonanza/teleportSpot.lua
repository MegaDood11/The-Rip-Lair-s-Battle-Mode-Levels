local onlinePlay = require("scripts/onlinePlay")
local onlinePlayPlayers = require("scripts/onlinePlay_players")
local spline = require("spline")

local tele = {}


local transitionStartCommand = onlinePlay.createCommand("teleportSpot_start",onlinePlay.IMPORTANCE_MAJOR)
local transitionStopCommand = onlinePlay.createCommand("teleportSpot_stop",onlinePlay.IMPORTANCE_MAJOR)


local teleportSprite = Graphics.loadImage(Misc.resolveFile("tele_orb.png"))

local states = {
    NONE = 0,
    GROW = 1,
    FLY = 2,
}
local teleImageFrames = {
    3,
    2,
}

local playersTransitionInfo = {}

tele.cooldown = 24
tele.duration = 0.75
tele.teleportBGOIDs = {751, 752, 753}
local idMap = {}

for k,v in ipairs(tele.teleportBGOIDs) do
    idMap[v] = true
end

function tele.onInitAPI()
    registerEvent(tele, "onStart")
    registerEvent(tele, "onTick")
    registerEvent(tele, "onCameraDraw")
end

local flameSprite = Graphics.loadImage(Misc.resolveFile("teleporter_flame.png"))

local flameEffects = {}

local function spawnFlameEffect(x, y)
    local f = {}
    f.l = x
    f.r = x + 32
    f.t = y
    f.b = y+64
    f.timer = (8 * #flameEffects) % 24

    table.insert(flameEffects, f)
end

function tele.onStart()
    --[[for k,v in BGO.iterate(tele.teleportBGOIDs) do
        spawnFlameEffect(v.x, v.y - 32)
    end]]
end

local function seekBGOofID(id, x, y)
    local closestDistance = math.huge
    local closestBGO = nil

    for k,v in BGO.iterate(id) do
        local x2,y2 = v.x + 0.5 * v.width, v.y + 0.5 * v.height

        if x2 ~= x or y2 ~= y then
            local dist = vector(x2 - x, y2 - y)
            if dist.sqrlength < closestDistance then
                closestDistance = dist.sqrlength
                closestBGO = v
            end
        end
    end

    return closestBGO
end

local function drawSplineCustom(spline, steps, halfwidth, priority, opacity)
    steps = steps or 50
    local ps = {}
    local idx = 1
    local ds = 1/steps
    local s = 0
    local dir = spline.startTan
    local pold = spline:evaluate(0)
    local tx = {}
    for i = 0,steps do
        local p = spline:evaluate(s)
        s = s+ds
        local texCoord = 0.5
        if i == 0 then
            texCoord = 0
        elseif i == steps then
            texCoord = 1
        end

        local normal = vector(dir.x, dir.y):rotate(-90):normalize() * halfwidth
        
        ps[idx] = p[1] + normal.x
        ps[idx+1] = p[2] + normal.y
        ps[idx+2] = p[1] - normal.x
        ps[idx+3] = p[2] - normal.y
        tx[idx] = texCoord
        tx[idx+1] = 0
        tx[idx+2] = texCoord
        tx[idx+3] = 1

        if i < steps then
            dir = spline:evaluate(s+ds) - p
        end
        
        idx = idx+4
    end
		
    Graphics.glDraw{
        vertexCoords = ps,
        textureCoords = tx,
        primitive = Graphics.GL_TRIANGLE_STRIP,
        priority = priority,
        sceneCoords = true,
        color = Color.purple .. opacity
    }
end


local function startTransition(p,bgoID,startX,startY,targetX,targetY)
    -- Set up data table if necessary
    local transitionInfo = playersTransitionInfo[p.idx]

    if transitionInfo == nil then
        transitionInfo = {}
        playersTransitionInfo[p.idx] = transitionInfo
    end

    -- Set up state
    p.forcedState = 498
    p.forcedTimer = 0

    transitionInfo.state = states.GROW
    transitionInfo.timer = 0

    transitionInfo.opacity = 0
    transitionInfo.angle = 0

    transitionInfo.speed = vector(p.speedX,p.speedY)

    transitionInfo.targetSection = Section.getIdxFromCoords(targetX,targetY)
    transitionInfo.splinePosition = 0
    transitionInfo.spline = spline.segment{
        start = vector(startX,startY),
        stop = vector(targetX,targetY),
        startTan = vector.zero2,
        stopTan = transitionInfo.speed * 100,
    }
    
    transitionInfo.cooldown = tele.cooldown
    transitionInfo.lastBGOID = bgoID

    --SFX.play("teleport-in.ogg")
    SFX.play(34)


    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and onlinePlayPlayers.ownsPlayer(p) then
        transitionStartCommand:send(0, startX,startY,targetX,targetY)
    end
end

local function stopTransition(p)
    local transitionInfo = playersTransitionInfo[p.idx]

    if transitionInfo == nil or transitionInfo.state == states.NONE then
        return
    end

    Effect.spawn(751, p.x + p.width*0.5,p.y + p.height*0.5)

    p.forcedState = FORCEDSTATE_NONE
    p.forcedTimer = 0

    p.speedX = transitionInfo.speed.x
    p.speedY = transitionInfo.speed.y

    transitionInfo.state = states.NONE
    transitionInfo.timer = 0
    transitionInfo.angle = 0

    --SFX.play("teleport-out.ogg")
    SFX.play(35)

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and onlinePlayPlayers.ownsPlayer(p) then
        transitionStopCommand:send(0)
    end
end

local function updatePlayer(p)
    local transitionInfo = playersTransitionInfo[p.idx]

    if transitionInfo == nil or transitionInfo.state == states.NONE then
        if transitionInfo ~= nil and transitionInfo.opacity > 0 then
            transitionInfo.opacity = math.max(0,transitionInfo.opacity - 0.1)
        end

        if p.forcedState ~= FORCEDSTATE_NONE or not onlinePlayPlayers.ownsPlayer(p) then
            return
        end

        -- Cooldown
        if transitionInfo ~= nil and transitionInfo.cooldown > 0 then
            for _,bgo in BGO.iterateIntersecting(p.x - 4,p.y - 4,p.x + p.width + 4,p.y + p.height + 4) do
                if bgo.id == transitionInfo.lastBGOID then
                    return
                end
            end

            transitionInfo.cooldown = transitionInfo.cooldown - 1
            return
        end

        -- Look for a BGO to warp with
        for _,startBGO in BGO.iterateIntersecting(p.x + 6,p.y + 6,p.x + p.width - 6,p.y + p.height - 6) do
            if idMap[startBGO.id] then
				for _,n in ipairs(BGO.get(tele.teleportBGOIDs)) do
					local targetBGO = seekBGOofID(n.id, startBGO.x + startBGO.width*0.5, startBGO.y + startBGO.height*0.5)

					if targetBGO then
						startTransition(p,n.id, startBGO.x + startBGO.width*0.5,startBGO.y + startBGO.height*0.5, targetBGO.x + targetBGO.width*0.5,targetBGO.y + targetBGO.height*0.5)
						break
					end
				end
            end
        end

        return
    end

    
    if transitionInfo.state == states.GROW then
        transitionInfo.timer = transitionInfo.timer + 2
        transitionInfo.opacity = math.min(transitionInfo.opacity + 0.05, 1)

        local step = transitionInfo.spline(0)
        p.x = step.x - 0.5 * p.width
        p.y = step.y - 0.5 * p.height

        if transitionInfo.timer > 24 then
            transitionInfo.state = states.FLY
            transitionInfo.timer = 0
            transitionInfo.angle = 0
        end
    elseif transitionInfo.state == states.FLY then
        transitionInfo.timer = transitionInfo.timer + 1

        transitionInfo.splinePosition = math.clamp(transitionInfo.timer/65/tele.duration,0,1)

        local step = transitionInfo.spline(transitionInfo.splinePosition)
        local newX = step.x - 0.5 * p.width
        local newY = step.y - 0.5 * p.height

        if p.x ~= newX or p.y ~= newY then
            transitionInfo.angle = math.deg(math.atan2(newY - p.y, newX - p.x))
            p.x = newX
            p.y = newY
        end

        if transitionInfo.splinePosition >= 1 and onlinePlayPlayers.ownsPlayer(p) then
            stopTransition(p)
        end
    end

    -- Set held NPC's position
    local holdingNPC = p.holdingNPC

    if holdingNPC ~= nil then
        holdingNPC.x = p.x + (p.width - holdingNPC.width)*0.5
        holdingNPC.y = p.y + (p.height - holdingNPC.height)*0.5
    end
end


function transitionStartCommand.onReceive(sourcePlayerIdx, startX,startY,targetX,targetY)
    startTransition(Player(sourcePlayerIdx),0, startX,startY,targetX,targetY)
end

function transitionStopCommand.onReceive(sourcePlayerIdx, startX,startY,targetX,targetY)
    stopTransition(Player(sourcePlayerIdx))
end

function onlinePlay.onDisconnect(playerIdx)
    playersTransitionInfo[playerIdx] = nil
end


function tele.onTick()
    for _,p in ipairs(Player.get()) do
        updatePlayer(p)
    end
end


local function drawFlameEffects(cam)
    local tick = lunatime.tick()
    local fvt = {}
    local ftx = {}
    local i = 1

    for k,v in ipairs(flameEffects) do
        if v.l <= cam.x + cam.width and v.r >= cam.x and v.t <= cam.y + cam.height and v.b >= cam.y then
            fvt[i] = v.l
            fvt[i+1] = v.t
            fvt[i+2] = v.r
            fvt[i+3] = v.t
            fvt[i+4] = v.l
            fvt[i+5] = v.b
            fvt[i+6] = v.r
            fvt[i+7] = v.t
            fvt[i+8] = v.l
            fvt[i+9] = v.b
            fvt[i+10] = v.r
            fvt[i+11] = v.b

            local t = (math.floor((v.timer + tick) * 0.125) % 3) * 0.25
            local b = t + 0.25
            
            ftx[i] = 0
            ftx[i+1] = t
            ftx[i+2] = 1
            ftx[i+3] = t
            ftx[i+4] = 0
            ftx[i+5] = b
            ftx[i+6] = 1
            ftx[i+7] = t
            ftx[i+8] = 0
            ftx[i+9] = b
            ftx[i+10] = 1
            ftx[i+11] = b
            i = i + 12
        end
    end

    if i > 1 then
        Graphics.glDraw{
            sceneCoords = true,
            vertexCoords = fvt,
            textureCoords = ftx, 
            primitive = Graphics.GL_TRIANGLES,
            priority = -70,
            texture = flameSprite
        }
    end
end

local function drawForPlayer(p)
    local transitionInfo = playersTransitionInfo[p.idx]

    if transitionInfo == nil then
        return
    end

    if transitionInfo.opacity > 0 then
        drawSplineCustom(transitionInfo.spline, nil, 2, -56, transitionInfo.opacity)
    end

    if transitionInfo.state ~= states.NONE then
        local width = teleportSprite.width/3
        local height = teleportSprite.height/2

        local sourceX = (math.floor(transitionInfo.timer * 0.125) % teleImageFrames[transitionInfo.state])*width
        local sourceY = (transitionInfo.state - 1)*height

        local splineCoords = transitionInfo.spline(transitionInfo.splinePosition)

        Graphics.drawBox{
            texture = teleportSprite,priority = -25,
            centred = true,sceneCoords = true,

            sourceWidth = width,sourceHeight = height,
            sourceX = sourceX,sourceY = sourceY,

            rotation = transitionInfo.angle,
            x = splineCoords.x,
            y = splineCoords.y,
        }

        -- Make the player invisible
        p:mem(0x142,FIELD_BOOL,true)
    end
end

function tele.onCameraDraw(camIdx)
    local cam = Camera(camIdx)

    drawFlameEffects(cam)

    for _,p in ipairs(Player.get()) do
        drawForPlayer(p)
    end


    --[[if transitionInfo.state ~= 0 then
        if transitionInfo.state < 3 then
            player:mem(0x142, FIELD_BOOL, true)
        end
        
        drawSplineCustom(transitionInfo.spline, nil, 2, -56, transitionInfo.opacity)

        local vt = {
            vector(-32, -32),
            vector(32, -32),
            vector(-32, 32),
            vector(32, 32),
        }

        local t = (math.floor(transitionInfo.timer * 0.125) % teleImageFrames[transitionInfo.state]) * 0.25
        local t1 = t + 0.25
        local th = (transitionInfo.state - 1) * 0.25
        local th1 = th + 0.25

        local tx = {
            t, th,
            t1, th,
            t, th1,
            t1, th1
        }

        for k,v in ipairs(vt) do
            vt[k] = v:rotate(transitionInfo.angle)
        end

        local splineCoords = transitionInfo.spline(transitionInfo.splinePosition)

        local x,y = splineCoords.x, splineCoords.y

        Graphics.glDraw{
            vertexCoords = {
                x + vt[1].x, y + vt[1].y,
                x + vt[2].x, y + vt[2].y,
                x + vt[3].x, y + vt[3].y,
                x + vt[4].x, y + vt[4].y,
            },
            textureCoords = tx,
            priority = -25,
            texture = teleportSprite,
            primitive = Graphics.GL_TRIANGLE_STRIP,
            sceneCoords = true
        }
    end]]
end

return tele