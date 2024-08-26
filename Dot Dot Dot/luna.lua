local battleGeneral = require("scripts/battleGeneral")
local paralx = require("paralx2")

local bg
local length = 0
local AHHHTIME = false

battleTimer = require("scripts/battleTimer")

function onStart()
	-- battleTimer.hurryTime = battleTimer.secondsLeft / 2
	-- battleTimer.set(180, false)
	
	length = battleTimer.secondsLeft
	
	for k,p in ipairs(Player.get()) do
		local e = paralx.get(p.section)
		
		if e then
			bg = e:get()
		end
	end
end

function onTick()
	if AHHHTIME then
		for k,v in BGO.iterate(333) do
			if lunatime.tick() % 64 == 0 then
				if RNG.randomInt(1, 18) == 1 then
					NPC.spawn(751, v.x + RNG.randomInt(-24, 24), v.y)
				end
			end
		end
	elseif battleTimer.secondsLeft <= length/2 then
		for k,v in BGO.iterate(333) do
			if lunatime.tick() % 128 == 0 then
				if RNG.randomInt(1, 20) == 1 then
					NPC.spawn(751, v.x + RNG.randomInt(-24, 24), v.y)
				end
			end
		end	
	elseif battleTimer.secondsLeft > length/2 then
		for k,v in BGO.iterate(333) do
			if lunatime.tick() % 256 == 0 then
				if RNG.randomInt(1, 28) == 1 then
					NPC.spawn(751, v.x + RNG.randomInt(-24, 24), v.y)
				end
			end
		end	
	end
end

function onDraw()
	-- Text.print(length, 10, 100)
	-- Text.print(battleTimer.secondsLeft, 10, 60)
	
	if battleTimer.secondsLeft == (battleTimer.hurryTime + 6) then
		Audio.MusicFadeOut(0, 4000)
	end
	
	-- if battleTimer.secondsLeft == length/2 then
		-- triggerEvent("halfwayBGChange")
	-- end
	
	if bg then
		for k,v in ipairs(bg) do
			if v.name == "Fire" then
				v.speedY = math.sin(lunatime.tick() * 0.06) * 1.5
				v.speedX = math.cos(lunatime.tick() * 0.02) * 2
			end
			if v.name == "Fire2" then
				v.speedY = math.sin(lunatime.tick() * 0.05) * 1
				v.speedX = math.cos(lunatime.tick() * 0.01) * 2
			end
			if v.name == "2011x" then
				v.speedY = math.sin(lunatime.tick() * 0.03) * 0.4
				-- v.speedX = math.cos(lunatime.tick() * 0.04)
			end
		end
	end
end

function battleGeneral.musicShouldBeSpedUp()
    if battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode] ~= nil and battleGeneral.musicShouldSpeedUpFuncs[battleGeneral.mode]() then
		Audio.MusicSetTempo(battleGeneral.musicSpedUpTempo)
    end

    if battleTimer.isActive and battleTimer.secondsLeft == battleTimer.hurryTime then --battleTimer.hurryTime
        Audio.MusicChange(0, "Dot Dot Dot/dotdotdot-lastMinute.ogg")
		triggerEvent("sceneChange")
		AHHHTIME = true
		
		for k,p in ipairs(Player.get()) do
			local e = paralx.get(p.section)
			
			if e then
				bg = e:get()
			end
		end
    end
    
    return false
end

function onEvent(e)
	if e == "sceneChange" then
		for k,v in Block.iterate() do --God I wish there was an easier way to do this
			if v.id == 9 then
				v:transform(14, false)
				v:setSize(64, 64)
			elseif v.id == 10 then
				v:transform(16, false)
				v:setSize(64, 64)
			elseif v.id == 11 then
				v:transform(15, false)
				v:setSize(64, 64)
			elseif v.id == 12 then
				v:transform(17, false)
				v:setSize(64, 64)
			elseif v.id == 13 then
				v:transform(18, false)
				v:setSize(64, 64)
			end
			
			if v.id == 19 then
				v:transform(43, false)
			elseif v.id == 20 then
				v:transform(44, false)
			elseif v.id == 39 then
				v:transform(45, false)
			elseif v.id == 40 then
				v:transform(46, false)
			elseif v.id == 41 then
				v:transform(47, false)
			elseif v.id == 42 then
				v:transform(48, false)
			end
		end
		
		for k,v in BGO.iterate() do
			if v.id == 1 then
				v:transform(2, false)
			elseif v.id == 3 then
				v:transform(4, false)
			end
		end
	end
end