--------------------------------------------------
-- Level code
-- Created 21:36 2025-8-4
--------------------------------------------------

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local timer = 0
local lastSong
local audioValue

local audioList = {
	"bollywood.mp3",
	"rox300.mp3",
	"skateorlive.mp3",
	"subboss.mp3",
	"thedarkone.mp3",
	"twindragons.mp3",
	"vegetablerock.mp3"
}

local audioLength = {48.8, 43.5, 42.7, 44.6, 44.1, 60.4, 51.1}

local finishhim = onlinePlay.createVariable("finishim","uint16",true,0)
local dofightpopup = false
local drawfightpopup = false
local fightpopup = Graphics.loadImage("fightpopup.png")
local fpframe = 0
local fpopacity = 1

local platform1 = {}
local platform2 = {}
local platform3 = {}
local gidplat1 = {}
local gidplat2 = {}
local currplat = 0
local lastplat = 0
local noplat = true

local dogidclouds = false

local exframe = Graphics.loadImage("exframe.png")

local exportraits = Graphics.loadImage("exportraits.png")
local exsilhouettes = Graphics.loadImage("exsilhouettes.png")
local exbacks = Graphics.loadImage("exbacks.png")
local exsilhouetteopac = 1

local gideonportrait = Graphics.loadImage("gideonportrait.png")
local gideonsilhouette = Graphics.loadImage("gideonsilhouette.png")
local gideonback = Graphics.loadImage("gideonback.png")
local gideonsilhouetteopac = 1

local exborder = Graphics.loadImage("exborder.png")

local showingex = true
local drawex = true
local drawexsilhouette = true
local exframe = 0

local neutralaudience = {}
local excitedaudience = {}

local explosions1 = {}
local explosions2 = {}
local hammerbros1 = {}
local hammerbros2 = {}

-- alright fuck it lets do this shit

function onStart()
	platform1 = Layer.get("clouds1")
	platform2 = Layer.get("clouds2")
	platform3 = Layer.get("clouds3")
	gidplat1 = Layer.get("gideonclouds1")
	gidplat2 = Layer.get("gideonclouds2")
	
	neutralaudience = Layer.get("neutral")
	excitedaudience = Layer.get("excited")
	
	hammerbros1 = Layer.get("hammerbros1")
	hammerbros2 = Layer.get("hammerbros2")
	
	NPC.spawn(287, -199904, -200576)
	NPC.spawn(287, -199712, -200576)
	NPC.spawn(287, -199520, -200576)
	NPC.spawn(287, -199328, -200576)
end

function onTick()
	explosions1 = Layer.get("explosions1")
	explosions2 = Layer.get("explosions2")
    if battleTimer.isActive and battleTimer.secondsLeft <= 60 and finishhim.value == 0 then
		finishhim.value = 1
		dofightpopup = true
		drawfightpopup = true
		dogidclouds = true
		Audio.MusicChange(player.section, "Chaos Theatre/music/gideonwrath.mp3", 1)
		
		Routine.run(function ()
			gideonsilhouetteopac = 1
			for i = 0,25,1 do
				gideonsilhouetteopac = gideonsilhouetteopac - 0.04
				Routine.waitFrames(1)
			end
		end)
		Routine.run(function ()
			Routine.waitFrames(90)
			explosions2:show(true)
			SFX.play(43)
			Routine.waitFrames(40)
			explosions2:hide(true)
			hammerbros2:show(true)
		end)
	end
	if battleTimer.isActive and (battleTimer.secondsLeft % 60) == 0 and battleTimer.secondsLeft > 60 and noplat then
		repeat
		currplat = RNG.randomInt(1, 3)
		until currplat ~= "lastplat"
		lastplat = currplat
		SFX.play(53)
		if currplat == 1 then
			platform1:show(true)
		end
		if currplat == 2 then
			platform2:show(true)
		end
		if currplat == 3 then
			platform3:show(true)
		end
		Routine.run(function ()
			noplat = false
			Routine.waitFrames(69)
			noplat = true
		end)
	end
	if battleTimer.isActive and (battleTimer.secondsLeft % 60) - 10 == 0 and battleTimer.secondsLeft > 60 and noplat then
		SFX.play(53)
		platform1:hide(true)
		platform2:hide(true)
		platform3:hide(true)
		NPC.spawn(287, -199904, -200576)
		NPC.spawn(287, -199712, -200576)
		NPC.spawn(287, -199520, -200576)
		NPC.spawn(287, -199328, -200576)
		Routine.run(function ()
			noplat = false
			Routine.waitFrames(69)
			noplat = true
		end)
	end
	if battleTimer.isActive and (battleTimer.secondsLeft <= 60) and dogidclouds then
		SFX.play(53)
		gidplat1:show(true)
		gidplat2:show(true)
		dogidclouds = false
	end
	if battleTimer.isActive and battleTimer.secondsLeft <= 1 then
		neutralaudience:hide(true)
		excitedaudience:show(true)
	end
end

function onEvent(eventName)
	if eventName == "hammers1" then
		Routine.run(function ()
			explosions1:show(true)
			SFX.play(43)
			Routine.waitFrames(40)
			explosions1:hide(true)
			hammerbros1:show(true)
		end)
	end
end

function onDraw()
	if finishhim.value == 0 then
		if not audioValue then
			audioValue = RNG.randomInt(0, 6)
			if not lastSong then
				Audio.MusicChange(0, "Chaos Theatre/music/" .. audioList[audioValue + 1])
				timer = audioLength[audioValue + 1]
				lastSong = audioValue
				
				Routine.run(function ()
					exsilhouetteopac = 1
					exframe = audioValue
					for i = 0,25,1 do
						exsilhouetteopac = exsilhouetteopac - 0.04
						Routine.waitFrames(1)
					end
				end)
			else
				if lastSong ~= audioValue then
					lastSong = nil
				end
			end
		else
			if Audio.MusicClock() >= timer then
				audioValue = nil
			end
		end
	end
	
	if dofightpopup then
		Routine.run(function ()
			dofightpopup = false
			for i = 0,8,1 do
				for i = 0,8,1 do
					Routine.waitFrames(1)
				end
				fpframe = 1
				for i = 0,8,1 do
					Routine.waitFrames(1)
				end
				fpframe = 0
			end
			for i = 0,8,1 do
				for i = 0,8,1 do
					fpopacity = fpopacity - 0.02
					Routine.waitFrames(1)
				end
				fpframe = 1
				for i = 0,8,1 do
					fpopacity = fpopacity - 0.02
					Routine.waitFrames(1)
				end
				fpframe = 0
			end
			drawfightpopup = false
		end)
	end
	if drawfightpopup then
		Graphics.drawImage(fightpopup, 260, 263, 0, fpframe * 74, 280, 74, fpopacity)
	end
	
	if finishhim.value == 0 then
		Graphics.drawImage(exbacks, 544, 0, 0, exframe * 114, 256, 114, 1)
		
		if drawex then
			Graphics.drawImage(exportraits, 544, 0, 0, exframe * 114, 256, 114, 1)
		end
		if drawexsilhouette then
			Graphics.drawImage(exsilhouettes, 544, 0, 0, exframe * 114, 256, 114, exsilhouetteopac)
		end
	else
		Graphics.drawImage(gideonback, 544, 0, 0, 0, 256, 114, 1)
		
		Graphics.drawImage(gideonportrait, 544, 0, 0, 0, 256, 114, 1)
		
		Graphics.drawImage(gideonsilhouette, 544, 0, 0, 0, 256, 114, gideonsilhouetteopac)
	end
	
	Graphics.drawImage(exborder, 536, 0, 0, 0, 264, 122, 1)
end

function onPlayerKill(v,p)
	for v,p in ipairs(Player.get()) do
		Routine.run(function ()
			neutralaudience:hide(true)
			excitedaudience:show(true)
			Routine.waitFrames(96)
			neutralaudience:show(true)
			excitedaudience:hide(true)
		end)
	end
end

-- PHEW! That was... a lot -o-;