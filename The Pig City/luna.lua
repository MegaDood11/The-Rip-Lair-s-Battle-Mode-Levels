--------------------------------------------------
-- Level code
-- Created 21:36 2025-8-4
--------------------------------------------------

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local pizzatime = onlinePlay.createVariable("pizzatime","uint16",true,0)
local pizzatimeimg = Graphics.loadImage("PIZZATIMEAHHHH.png")
local pizzatimeimgY = 600
local pizzatimeimgframe = 0

local pizzanim = {}
local pizzanimconcluded = false

-- Run code on level start
function onStart()
	
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    if battleTimer.isActive and battleTimer.secondsLeft <= 60 and pizzatime.value == 0 then
		Audio.MusicChange(player.section, "The Pig City/The Death That I Deservioli.mp3", 1)
		if pizzanimconcluded == false then
			pizzanimconcluded = true
			pizzanim = Routine.run(function ()
				for i = 0,120,1 do
					for i = 0,16,1 do
						pizzatimeimgY = pizzatimeimgY - 4
						Routine.waitFrames(1)
					end
					pizzatimeimgframe = 1
					for i = 0,16,1 do
						pizzatimeimgY = pizzatimeimgY - 4
						Routine.waitFrames(1)
					end
					pizzatimeimgframe = 0
				end
			end)
		end
	end
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    --Your code here
end

function onDraw()
	Graphics.drawImage(pizzatimeimg, 275, pizzatimeimgY, 0, pizzatimeimgframe * 200, 250, 200)
end