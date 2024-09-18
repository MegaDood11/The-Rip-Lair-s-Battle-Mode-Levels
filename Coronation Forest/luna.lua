local battleGeneral = require("scripts/battleGeneral")
local battleHUD = require("scripts/battleHUD")
local battleCamera = require("scripts/battleCamera")
local battleMessages = require("scripts/battleMessages")
local battleStart = require("scripts/battleStart")
local battleStars = require("scripts/battleStars")
local battlePlayer = require("scripts/battlePlayer")
local onlinePlay = require("scripts/onlinePlay")

local spawnHimCMD = onlinePlay.createCommand("spawnHim", onlinePlay.IMPORTANCE_MAJOR)
local spawnHimbutFreakyCMD = onlinePlay.createCommand("spawnHimbutFreaky", onlinePlay.IMPORTANCE_MAJOR)

local bg
local length = 0
local AHHHTIME = false

local sectionObj
local b
local him = nil

local hisImage = Graphics.loadImageResolved("hisIcon.png")

battleTimer = require("scripts/battleTimer")

local voicelines = {
	--death
	again = "voicelines/again.ogg",
	looking = "voicelines/areyoulookingforme.ogg",
	believe = "voicelines/ibelieve.ogg",
	makethemhappy = "voicelines/makethemhappy.ogg",
	him = "voicelines/HIM.ogg",
	king = "voicelines/king.ogg",
	
	--classic
	morsel = "voicelines/morsel.ogg",
	dontyoudare = "voicelines/dontyoudare.ogg",
	bowtome = "voicelines/bowtome.ogg",
	
	--star
	collectit = "voicelines/collectit.ogg",
	amazingwork = "voicelines/amazingwork.ogg",
	donesowell = "voicelines/donesowell.ogg",
	
	--what
	freaky = "voicelines/freakygod.ogg",
}

local function spawnHim(p)
   	local v = NPC.spawn(992, -197600, -200336)
	him = v
	SFX.play(voicelines.him, 0.5)
end

function spawnHimCMD.onReceive(sourcePlayerIdx, playerIdx)
    local p = Player(playerIdx)

    spawnHim(p)
end

local function spawnHimbutFreaky(p)
   	local v = NPC.spawn(993, -197600, -200336)
	him = v
	SFX.play(voicelines.freaky, 0.5)
end

function spawnHimbutFreakyCMD.onReceive(sourcePlayerIdx, playerIdx)
    local p = Player(playerIdx)

    spawnHimbutFreaky(p)
end

function onStart()
	-- battleTimer.hurryTime = battleTimer.secondsLeft / 2
	-- battleTimer.set(68, false)
	
	-- SFX.play(10)
	
	-- length = battleTimer.secondsLeft
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

local function getPositionOnMap(x,y,b)
    local mapX = math.invlerp(b.left,b.right,x)
    local mapY = math.invlerp(b.top,b.bottom,y)

    return mapX,mapY
end

function onHUDDraw(camIdx)
	-- Text.print(length, 10, 100)
	-- Text.print(him, 10, 60)

	local sectionIdx,mapsShared = getMapSection(camIdx)
    if sectionIdx == nil then
        return
    end
	
    local cam = Camera(camIdx)

    local screenWidth,screenHeight = battleGeneral.getScreenSize()
	
	local sectionObj = Section(sectionIdx)
	local b = sectionObj.boundary
	
    local star = him
	
    local sectionWidth = b.right - b.left
    local sectionHeight = b.bottom - b.top
	
    local scale = 1/math.max(sectionWidth,sectionHeight)
	
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
	
	for i, v in ipairs(NPC.get(992)) do
		if i > 1 then
			v:kill(9)
		elseif i == 1 then
			him = v
		end
		-- Misc.dialog(i)
	end
	
	--The Forest God's Icon
    if star ~= nil and star.isValid and star.section == sectionIdx then
        local relativeX,relativeY = getPositionOnMap(star.x + star.width*0.5,star.y + star.height*0.5,b)

        Graphics.drawBox{
            texture = hisImage, priority = battleHUD.priority + 0.1, centered = true,

            x = x + width*relativeX,
            y = y + height*relativeY,
        }
    end
end

function battleGeneral.musicShouldBeSpedUp()
    if battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode] ~= nil and battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode]() then
		Audio.MusicSetTempo(battleGeneral.musicSpedUpTempo)
    end

    if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.hurryTime then --battleTimer.hurryTime
		Audio.MusicChange(0, "Coronation Forest/ladder.ogg")
		if not AHHHTIME then
			triggerEvent("sceneChange")
		end
		AHHHTIME = true
    end
    
    return false
end

function onEvent(e)
	if e == "sceneChange" then
		player.sectionObj.darkness.effect.ambient = Color.fromHexRGBA(0x615A5AFF)
	
		for k,v in BGO.iterate() do
			if v.id == 2 then
				v:transform(7, false)
			elseif v.id == 51 then
				v:transform(8, false)
			end
		end
		
		local rng = RNG.randomInt(1, 100)
		
		if rng ~= 100 then
			if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
				spawnHimCMD:send(0)
			elseif onlinePlay.currentMode == onlinePlay.MODE_OFFLINE then
				spawnHim(p)
			end
			
			battleMessages.spawnStatusMessage("HIM", Color.fromHexRGBA(0x984040FF))
		elseif rng == 100 then
			if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
				spawnHimbutFreakyCMD:send(0)
			elseif onlinePlay.currentMode == onlinePlay.MODE_OFFLINE then
				spawnHimbutFreaky(p)
			end
			
			battleMessages.spawnStatusMessage("I am FREAKY and you are in my FREAKY FOREST...", Color.fromHexRGBA(0x984040FF))
		end
	end
end

function onPlayerKill(e, p)
	if battleGeneral.mode ~= battleGeneral.gameMode.CLASSIC then
		if not AHHHTIME then
			local rng = RNG.randomInt(1, 2)
			
			if rng == 1 then
				SFX.play(voicelines.again, 0.7)
				battleMessages.spawnStatusMessage("again?", Color.fromHexRGBA(0xFFFFFFFF))
			end
		
			if rng == 2 then
				SFX.play(voicelines.makethemhappy, 0.7)
				battleMessages.spawnStatusMessage("You are not making THEM happy.", Color.fromHexRGBA(0xFFFFFFFF))
			end
		elseif AHHHTIME then
			local rng = RNG.randomInt(1, 3)
		
			if rng == 1 then
				SFX.play(voicelines.believe, 0.7)
				battleMessages.spawnStatusMessage("I BELIEVE I AM THE GOD OF THIS FOREST", Color.fromHexRGBA(0x984040FF))
			end
			
			if rng == 2 then
				SFX.play(voicelines.him, 0.5)
				battleMessages.spawnStatusMessage("HIM", Color.fromHexRGBA(0x984040FF))
			end
			
			if rng == 3 then
				SFX.play(voicelines.king, 0.7)
				battleMessages.spawnStatusMessage("FOR HE IS KING", Color.fromHexRGBA(0x984040FF))
			end
		end
	end
	
	if battleGeneral.mode == battleGeneral.gameMode.CLASSIC then
		if p.data._battle.lives == 1 then
			local rng = RNG.randomInt(1, 3)
		
			if rng == 1 then
				SFX.play(voicelines.morsel, 1)
				battleMessages.spawnStatusMessage("Another morsel to join me in the forest.", Color.fromHexRGBA(0x984040FF))
			end
			
			if rng == 2 then
				SFX.play(voicelines.dontyoudare, 1)
				battleMessages.spawnStatusMessage("DON'T YOU DARE   TOUCH MY PREY", Color.fromHexRGBA(0x984040FF))
			end
			
			if rng == 3 then
				SFX.play(voicelines.bowtome, 1)
				battleMessages.spawnStatusMessage("YOU BOW TO ME   CROOK", Color.fromHexRGBA(0x984040FF))
			end
		end
	end
end

function onPostNPCCollect(v,p)
    if not battleStars.collectableIDMap[v.id] then
        return
    end

    local isSpawnedStar = (v == battleStars.spawnedNPC)
	
	if isSpawnedStar then
		local rng = RNG.randomInt(1, 3)
		
		if rng == 1 then
			SFX.play(voicelines.collectit, 0.7)
		end
		
		if rng == 2 then
			SFX.play(voicelines.amazingwork, 0.7)
		end

		if rng == 3 then
			SFX.play(voicelines.donesowell, 0.7)
		end		
	end
end