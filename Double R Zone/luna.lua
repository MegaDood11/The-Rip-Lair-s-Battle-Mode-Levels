local blockRespawning = require("scripts/blockRespawning")

local onlinePlay = require("scripts/onlinePlay")
local battleGeneral = require("scripts/battleGeneral")
local battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local img1 = Graphics.loadImageResolved("Roll1.png")
local img2 = Graphics.loadImageResolved("Roll2.png")
local img3 = Graphics.loadImageResolved("Roll3.png")
local img4 = Graphics.loadImageResolved("Roll4.png")
local img5 = Graphics.loadImageResolved("Roll5.png")
local img6 = Graphics.loadImageResolved("Roll6.png")
local img7 = Graphics.loadImageResolved("Roll7.png")
local img8 = Graphics.loadImageResolved("Roll8.png")
local img9 = Graphics.loadImageResolved("Roll9.png")
local img10 = Graphics.loadImageResolved("Roll10.png")
local img11 = Graphics.loadImageResolved("Roll11.png")
local current = {img1, img2, img3, img4, img5, img6, img7, img8, img9, img10, img11}
local image = current[1]
local timer = onlinePlay.createVariable("timer","uint16",true,0)
local timer2 = onlinePlay.createVariable("timer2","uint16",true,0)
local thing = onlinePlay.createVariable("thing","uint16",true,0)
local currentPosition = onlinePlay.createVariable("currentPosition","uint16",true,1)

function battleGeneral.musicShouldBeSpedUp()
    return false
end

function onDraw()
	
	
	if not Misc.isPaused() then
		thing.value = thing.value + 1
		if (battleTimer.isActive and battleTimer.secondsLeft >= battleTimer.optionTimeValues[battleOptions.getModeRuleset().timeLimit] - 5) or thing.value <= 2 then
			return
		end
		
		if not thing2 then
			Audio.MusicChange(0, "Double R Zone/Rick.ogg")
			Section(player.section).darkness.enabled = false
			thing2 = true
		end

		timer.value = timer.value + 0.15625
		
		if timer.value >= 11 then
			timer2.value = timer2.value + 1
			timer.value = 0
		end
		
		if timer2.value > 17 or (currentPosition.value == 11 and timer2.value > 11) then
			currentPosition.value = currentPosition.value + 1
			if currentPosition.value > 11 then currentPosition.value = 1 end
			timer2.value = 0
			timer.value = 0
			image = current[currentPosition.value]
		end

		Graphics.drawBox{
			texture = image,
			x = -199856,
			y = -200576,
			sceneCoords = true,
			sourceX = math.floor(timer.value) * 480,
			sourceY = timer2.value * 375,
			sourceWidth = 480,
			sourceHeight = 375,
			priority = -90,
			centered = false,
			rotation = 0,
			width = 480,
			height = 375
		}
	end
end