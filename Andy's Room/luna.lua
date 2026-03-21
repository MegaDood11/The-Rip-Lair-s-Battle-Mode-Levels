local blockRespawning = require("scripts/blockRespawning")
local onlinePlay = require("scripts/onlinePlay")
local battleHUD = require("scripts/battleHUD")
local battleGeneral = require("scripts/battleGeneral")
blockRespawning.defaultRespawnTime = 32*32

local randomTable = onlinePlay.createVariable("randomTable","uint16",true,0)
local randomSpawn = onlinePlay.createVariable("randomSpawn","uint16",true,1)
local cooldown = onlinePlay.createVariable("cooldown","uint16",true,0)

local ballImage = Graphics.loadImageResolved("ballIcon.png")

function battleGeneral.musicShouldBeSpedUp()
    return false
end

local function spawnStuff()
	local r = Routine.run(function()
		Routine.waitFrames(16)
		if randomTable.value <= 70 then
			randomSpawn.value = RNG.randomInt(1,12)
			Effect.spawn(751, -199964, -200128, randomSpawn.value)
			SFX.play(tostring(randomSpawn.value) .. ".wav")
			cooldown.value = 64
		elseif randomTable.value > 80 and randomTable.value <= 88 then
			local n = NPC.spawn(9, -199964, -200128, 0, false)
			n.speedX = 4
			n.speedY = -14
			n.direction = 1
			SFX.play(7)
			cooldown.value = 128
		elseif randomTable.value > 88 and randomTable.value <= 94 then
			local n = NPC.spawn(287, -199964, -200128, 0, false)
			n.speedX = 4
			n.speedY = -14
			n.direction = 1
			n.data.FRIENDINSIDEMEBOXACTIVENPC = true
			SFX.play(7)
			cooldown.value = 128
		elseif randomTable.value > 94 and randomTable.value <= 98 then
			local n = NPC.spawn(293, -199964, -200128, 0, false)
			n.speedX = 4
			n.speedY = -14
			n.direction = 1
			SFX.play(7)
			cooldown.value = 160
		elseif randomTable.value > 98 then
			for _,n in ipairs(NPC.get(752)) do
				n.data.friend = true
				cooldown.value = 288
			end
		end
	end)
end

local sectionObj
local b
local ball = nil

function onTick()
	local t = Player.get()
	cooldown.value = math.clamp(cooldown.value - 1,0,100000)

	for _,n in ipairs(NPC.get()) do
		if n.data.FRIENDINSIDEMEBOXACTIVENPC then
			if n.id ~= 9 then n.x = n.x + 2.25 end
			if n.collidesBlockBottom or (n.speedY > 0 and n.id == 34) then
				n.data.FRIENDINSIDEMEBOXACTIVENPC = nil
			end
		end
	end
	
	for i=1,#t do
		local plr = t[i]
		if plr.x < -199868 and plr.y > -200128 then
			plr.x = -199964
			plr.data.FRIENDINSIDEMEBOXACTIVE = true
			plr.data.FRIENDINSIDEMEBOXACTIVETIMER = 0
			plr.speedY = -14
			SFX.play(Misc.resolveSoundFile("crash-switch"))
			if cooldown.value <= 0 then
				spawnStuff(v)
				randomTable.value = RNG.randomInt(1,102)
			end
		end

		if plr.data.FRIENDINSIDEMEBOXACTIVE then
			plr.x = plr.x + 4
			plr.speedX = 0
			plr.data.FRIENDINSIDEMEBOXACTIVETIMER = plr.data.FRIENDINSIDEMEBOXACTIVETIMER + 1
			if plr.data.FRIENDINSIDEMEBOXACTIVETIMER >= 48 then
				plr.data.FRIENDINSIDEMEBOXACTIVETIMER = 0
				plr.data.FRIENDINSIDEMEBOXACTIVE = nil
				plr.speedX = 8
			end
		end
	end
	
	if not ball then
		for _,v in ipairs(NPC.get(751)) do
			ball = v
		end
	end
end


--****************************************
--Credits to Deltom for this block of code
--****************************************

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

local function getPositionOnMap(x,y,b)
    local mapX = math.invlerp(b.left,b.right,x)
    local mapY = math.invlerp(b.top,b.bottom,y)

    return mapX,mapY
end

function onHUDDraw(camIdx)
	local sectionIdx,mapsShared = getMapSection(camIdx)
    if sectionIdx == nil then
        return
    end
	
    local cam = Camera(camIdx)

    local screenWidth,screenHeight = battleGeneral.getScreenSize()
	
	local sectionObj = Section(sectionIdx)
	local b = sectionObj.boundary
	
    local star = ball
	
    local sectionWidth = b.right - b.left
    local sectionHeight = b.bottom - b.top
	
    local scale = 1.5/math.max(sectionWidth,sectionHeight)
	
    local width = battleHUD.mapSize*sectionWidth*scale
    local height = battleHUD.mapSize*sectionHeight*scale
    local x = screenWidth - width - battleHUD.normalPadding
    local y = screenHeight - height - battleHUD.normalPadding
	
    if battleCamera.splitMode == battleCamera.SPLIT_MODE.VERTICAL then
        y = y - cam.renderY
        
        if mapsShared then
            x = (screenWidth - width)*0.5 - cam.renderX
        elseif camIdx == 1 then
            x = cam.width - width - battleHUD.normalPadding
        else
            x = battleHUD.normalPadding
        end
    elseif battleCamera.splitMode == battleCamera.SPLIT_MODE.HORIZONTAL then
        x = x - cam.renderX

        if mapsShared then
            y = (screenHeight - height)*0.5 - cam.renderY
        elseif camIdx == 1 then
            y = camera.height - height - battleHUD.normalPadding
        else
            y = battleHUD.normalPadding
        end
    end
	
	for i, v in ipairs(NPC.get(751)) do
		if i > 1 then
			v:kill(9)
		elseif i == 1 then
			ball = v
		end
		-- Misc.dialog(i)
	end


	local relativeX,relativeY = getPositionOnMap(star.x + star.width*0.5,star.y + star.height*0.5,b)

	Graphics.drawBox{
		texture = ballImage, priority = battleHUD.priority + 0.1, centered = true,

		x = x + width*relativeX,
		y = y + height*relativeY,
	}
end


-- Run code on level start
function onStart()
    --Your code here
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Buzz"):show(true)
	end
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Hamm"):show(true)
	end
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Rex"):show(true)
	end
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Robot"):show(true)
	end
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Potato Head"):show(true)
	end
	if RNG.randomInt(1,5) == 1 then
		Layer.get("Rocky"):show(true)
	end
end