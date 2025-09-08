local birdIcon = Graphics.loadImageResolved("birdIcon.png")
local b

local onlinePlay = require("scripts/onlinePlay")
local battleGeneral = require("scripts/battleGeneral")
local battleCamera = require("scripts/battleCamera")
local battlePlayer = require("scripts/battlePlayer")
local battleHUD = require("scripts/battleHUD")

local timer = onlinePlay.createVariable("timer","uint16",true,0)
local seagull = onlinePlay.createVariable("seagull","uint16",true,0)

function onStart()
	Section(0).backgroundID = RNG.randomInt(31,33)
end

local function isActiveseagull(seagullNPC)
    local data = seagullNPC.data._basegame

    return (data.initialized and (data.state == 3 or data.state == 4))
end

local mixtapeSound = SFX.open(Misc.resolveSoundFile("SFX/Pirates Of The Caribbean Theme Song"))
local mixtapeSoundObj

local mixtapeConstantRadius = 192
local mixtapeFadeRadius = 800

local mixtapeMaxVolume = 0.5

-- Gets the distance between a box and a goal point.
-- If it would be faster to wrap around than it would be to move normally, it will move
-- in the opposite direction in the expectation that it will wrap.
local function getDistanceGivenSectionWrap(x,y,width,height, goalX,goalY, sectionObj)
    local bounds = sectionObj.boundary

    local dx = goalX - (x + width*0.5)
    local dy = goalY - (y + height*0.5)

    -- Horizontal wrap
    if sectionObj.wrapH then
        if dx > 0 then -- B is below A
            -- Would it be faster to go up and wrap around?
            local preWrapDistance = math.max(0,(x + width) - bounds.left)
            local postWrapDistance = math.max(0,(bounds.right + width*0.5) - goalX)
            local totalDistance = preWrapDistance + postWrapDistance

            if totalDistance < dx then
                dx = -totalDistance
            end
        elseif dx < 0 then -- B is above A
            -- Would it be faster to go down and wrap around?
            local preWrapDistance = math.max(0,bounds.right - x)
            local postWrapDistance = math.max(0,goalX - (bounds.left - width*0.5))
            local totalDistance = preWrapDistance + postWrapDistance

            if totalDistance < -dx then
                dx = totalDistance
            end
        end
    end

    -- Vertical wrap
    if sectionObj.wrapV then
        if dy > 0 then -- B is below A
            -- Would it be faster to go up and wrap around?
            local preWrapDistance = math.max(0,(y + height) - bounds.top)
            local postWrapDistance = math.max(0,(bounds.bottom + height*0.5) - goalY)
            local totalDistance = preWrapDistance + postWrapDistance

            if totalDistance < dy then
                dy = -totalDistance
            end
        elseif dy < 0 then -- B is above A
            -- Would it be faster to go down and wrap around?
            local preWrapDistance = math.max(0,bounds.bottom - y)
            local postWrapDistance = math.max(0,goalY - (bounds.top - height*0.5))
            local totalDistance = preWrapDistance + postWrapDistance

            if totalDistance < -dy then
                dy = totalDistance
            end
        end
    end

    return dx,dy
end

local function getMixtapeVolumeForseagull(seagullNPC)
    local maxVolume = 0

    for _,p in ipairs(Player.get()) do
        if (onlinePlay.currentMode == onlinePlay.MODE_OFFLINE or p.idx == battleCamera.onlineFollowedPlayerIdx) and battlePlayer.getPlayerIsActive(p) then
            local distanceX,distanceY = getDistanceGivenSectionWrap(seagullNPC.x,seagullNPC.y,seagullNPC.width,seagullNPC.height, p.x + p.width*0.5,p.y + p.height*0.5, seagullNPC.sectionObj)
            local distance = math.sqrt(distanceX*distanceX + distanceY*distanceY)

            local volume = math.clamp(1 - (distance - mixtapeConstantRadius)/mixtapeFadeRadius,0,1)

            maxVolume = math.max(maxVolume,volume)
        end
    end

    return maxVolume
end

local function getMixtapeVolume()
    local seagullExists = false
    local maxVolume = 0

    for _,seagullNPC in NPC.iterate(958) do
        if isActiveseagull(seagullNPC) then
            maxVolume = math.max(maxVolume,getMixtapeVolumeForseagull(seagullNPC))
            seagullExists = true
        end
    end

    return seagullExists,maxVolume
end

-- takes start and makes it get closer to goal, at speed change
local function approach(start,goal,change)
    if start > goal then
        return math.max(goal,start - change)
    elseif start < goal then
        return math.min(goal,start + change)
    else
        return goal
    end
end

function onTick()

	for _,p in ipairs(Player.get()) do
		if p.y > -200096 and not p.data.MutinyLevelSplashSound and p.deathTimer <= 0 and p.forcedState == 0 and not p:mem(0x16E, FIELD_BOOL) then
			SFX.play("SFX/Splash.wav")
			p.data.MutinyLevelSplashSound = true
			Effect.spawn(751, p.x - 48, -200096 - 88, Section(0).backgroundID - 30)
		end
	end
	
	--Interactions with other npcs
	for _,v in ipairs(NPC.get()) do
	
		if v.id ~= 954 and v.id ~= 13 and v.id ~= 265 and v.id ~= 171 and v.id ~= 292 and v.id ~= 753 and v.id ~= 291 and v.id ~= 266 and not NPC.config[v.id].nogravity then
			if v.y > -200096 and not v.data.MutinyLevelSplashSound then
				SFX.play("SFX/Splash.wav")
				v.data.MutinyLevelSplashSound = true
				Effect.spawn(751, v.x - 48, -200096 - 88, Section(0).backgroundID - 30)
			end
		end
	
		for _,n in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
			if Colliders.collide(n, v) and (n.id >= 752 and n.id <= 765) and n.data.state == 0 then
				if (NPC.config[v.id].isShell or v.id == 45 or v.id == 263) and v.heldIndex == 0 then
					SFX.play(NPC.config[n.id].sound)
					n.data.state = 1
					n.ai2 = 1
					n.speedX = 4 * v.direction
					n.speedY = -5
					n.ai3 = 5
				elseif v.id == 17 then
					n.data.state = 1
					SFX.play(NPC.config[n.id].sound)
					thing = vector.v2(
						(v.x) - (n.x + n.width * 0.5),
						(v.y) - (n.y + n.height * 0.5)
					):normalize() * -8
					
					n.speedX = thing.x
					n.speedY = -8
				end
			end
		end
	end
	
	timer.value = timer.value + 1
	if timer.value == 1600 then
		if seagull.value == 0 then
			local v = NPC.spawn(752, RNG.irandomEntry{-199904, -196064}, -200976, player.section, false)
			v.direction = math.sign(v.x - -198560)
			seagull.value = 1
		end
		timer.value = 0
	end
	
	local seagullExists,mixtapeVolume = getMixtapeVolume()

    if seagullExists then
        if mixtapeSoundObj == nil or not mixtapeSoundObj:isPlaying() then
            mixtapeSoundObj = SFX.play{sound = mixtapeSound,volume = mixtapeVolume*mixtapeMaxVolume,loops = 0}
        else
            mixtapeSoundObj.volume = mixtapeVolume*mixtapeMaxVolume
        end
    else
        if mixtapeSoundObj ~= nil and mixtapeSoundObj:isPlaying() then
            mixtapeSoundObj:stop()
        end
    end

    Audio.MusicVolume(approach(Audio.MusicVolume(),(1 - mixtapeVolume)*51,1))
	
	for _,n in ipairs(NPC.get(134)) do
		n.ai1 = 0
		n.ai2 = 0
		NPC.config[n.id].grabtop = false
		NPC.config[n.id].grabside = false
		
		if n.heldIndex == 0 and (n.collidesBlockBottom or n.collidesBlockUp or n.collidesBlockLeft or n.collidesBlockRight) then
			n:harm()
		end
	end
	
	for _,v in ipairs(NPC.get(154)) do
		for _,n in ipairs(NPC.getIntersecting(v.x - 8, v.y - 8, v.x + v.width + 8, v.y + v.height + 8)) do
			if NPC.config[n.id].isHot then
				v:kill(2)
				n:kill(9)
			end
		end
	end
end

function onPostExplosion(e, plr)
	for _,v in ipairs(Colliders.getColliding{a = e.collider, b = 154, btype = Colliders.NPC}) do
		v:kill(2)
	end
end

function onNPCKill(e, v, r)
	if v.id == 752 or (v.id == 263 and v.ai1 == 752) then
		seagull.value = 0
		timer.value = 0
	end
	
	if v.id == 154 and r ~= HARM_TYPE_OFFSCREEN then
		Explosion.spawn(v.x + v.width * 0.5, v.y + v.height * 0.5, 2)
	end
end

function onPlayerKill()
	for _,p in ipairs(Player.get()) do
		p.data.MutinyLevelSplashSound = nil
	end
end

local function getPositionOnMap(x,y,b)
    local mapX = math.invlerp(b.left,b.right,x)
    local mapY = math.invlerp(b.top,b.bottom,y)

    return mapX,mapY
end

local function getMapSection(camIdx)
    if battleCamera.isSplitScreen() then
        -- If both players are in the same section, display it in the middle of the screen
        local section1 = battleCamera.getCameraSection(1)
        local section2 = battleCamera.getCameraSection(2)

        if section1 == section2 then
            return section1,true
        end

        -- Otherwise, each camera will have its own map
        if camIdx == 1 then
            return section1,false
        else
            return section2,false
        end
    end

    return battleCamera.getCameraSection(1),false
end