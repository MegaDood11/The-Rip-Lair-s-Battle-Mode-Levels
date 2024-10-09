local spawnzones = require("spawnzones")
local utils = require("npcs/npcutils")
local onlinePlay = require("scripts/onlinePlay")
local battleGeneral = require("scripts/battleGeneral")
local battleTimer = require("scripts/battleTimer")

local targetTimer = onlinePlay.createVariable("targetTimer","uint16",true,960)
local cannonTimer = onlinePlay.createVariable("cannonTimer","uint16",true,0)
local cannonTimerOffset = onlinePlay.createVariable("cannonTimerOffset","uint16",true,0)
local currentSide = onlinePlay.createVariable("currentSide","sint8",true,RNG.randomEntry{-1,1})
local cooldown = onlinePlay.createVariable("cooldown","uint16",true,0)
local hasShot = false 
local opac = 0
local image = nil
local cannonSpawnPoint = {}
local sides = {
	[-1] = {
		effect = 751,
		npc = 696,
		xCoords = {
			[1] = -200000,
			[2] = -199872
		},
		yCoords = -200384,
	},
	[1] = {
		effect = 753,
		npc = 695,
		xCoords = {
			[1] = -196232,
			[2] = -196232
		},
		yCoords = RNG.randomInt(-200464,-200560),
	}
}

function battleGeneral.musicShouldBeSpedUp()
	if battleTimer.isActive and battleTimer.secondsLeft == 60 and Audio.MusicGetPos() < 279 then
		Audio.MusicSetPos(279)
	end
--
    if battleTimer.isActive and battleTimer.secondsLeft > 0 
	and battleTimer.secondsLeft % 60 == 0 and lunatime.tick() > 1
	and cooldown.value <= 0 then	-- battleTimer.hurryTime then --battleTimer.hurryTime
        --Audio.MusicChange(0, "Todd-Way Street/TORNADO-PINCH.ogg")
		image = Graphics.loadImageResolved("Free Birds/"..battleTimer.secondsLeft / 60 ..".png")
		opac = 0.75
		cooldown.value = 65
		if battleTimer.secondsLeft > 60 then
			SFX.play("Free Birds/ominous.ogg")
		else
			SFX.play("Free Birds/today.ogg")
			triggerEvent("pinch_mode")
		end
    end
--]]
    return false
end

function onTick()
	--battleTimer.framesLeft = math.min(battleTimer.framesLeft,64*(61 * 4))
	cannonTimer.value = cannonTimer.value + 1
	opac = math.max(opac - 0.005, 0)
	cooldown.value = math.max(cooldown.value - 1,0)
	local timer = cannonTimer.value
	local timerOffset = cannonTimerOffset.value
	local side = sides[currentSide.value]
	
	--Once cannonTimer reaches 13 seconds, spawn some cannonball effects on the left side of the screen
	if timer >= 832-timerOffset and timer <= 880-timerOffset then
		if timer % 12 == 0 then
			SFX.play(Misc.resolveSoundFile("launchbarrel_fire"))
			sides[1].yCoords = RNG.randomInt(-200464,-200560)
			local e = Effect.spawn(249, RNG.randomInt(side.xCoords[1], side.xCoords[2]), side.yCoords)
			local n = Effect.spawn(side.effect, e.x, e.y)
			n.speedY = -8
		end
		
		--Get the positions of where the cannonballs will spawn
		if timer == 879-timerOffset then
			for i = 1,10 do
				cannonSpawnPoint[i] = RNG.randomInt(-200000, -196256)
			end
		end
		
	--Spawn some warning indicators, 10 across the map
	elseif timer >= 900-timerOffset and timer <= 980-timerOffset then
		if timer % 8 == 1 then
			SFX.play(26)
		end
		
		if timer == 900-timerOffset then --timer == 960/timerOffset + 1 then
			for i = 1,10 do
				Effect.spawn(752, cannonSpawnPoint[i], -200384)
			end
			hasShot = true
		end
		
	else
	
		--Spawn the cannonballs down onto the map
		if timer == 981-timerOffset then
			for i = 1,10 do
				local n = NPC.spawn(side.npc, cannonSpawnPoint[i], -200736, player.section, false)
				n.speedX = 0
				n.speedY = 10
			end
		end
		
		--Reset cannonTimer after this
		if timer >= 1108-timerOffset then
			cannonTimer.value = 0
			currentSide.value = currentSide.value * -1
			hasShot = false
		end
	end
	
	--Have the SMBX2 cannonballs harm NPCs too, it's a battle against the turkeys, afterall
	for _,n in NPC.iterate{695,696} do
		for _,p in NPC.iterateIntersecting(n.x,n.y,n.x+n.width,n.y+n.height) do 
			if NPC.HITTABLE_MAP[p.id] and p.id ~= n.id then
				p:harm()
			end
		end
		if n.id == 695 then
			Effect.spawn(265,n.x+RNG.randomInt(0,n.width),n.y)
		end
	end
	
	for _,n in NPC.iterate(1) do
		if n.isValid then n:harm(3) end
	end
	
end


function onDraw()
	--Text.print(player.x,100,100)
	--Text.print(player.y,100,120)
	if image and opac > 0 then
		Graphics.drawBox{
			texture = image,
			x = 0 + camera.width/2,
			y = 0 + camera.height/2,
			color = Color.white .. opac,
			centered = true,
			priority = 4,
		}	
	end
	if battleTimer.secondsLeft <= 60 then
		Graphics.drawScreen{
			priority = -99.9,
			color = Color.orange .. 0.5 -- + math.sin(lunatime.tick() * 0.05) * 5,
		}
	end

	--makes the pumpkin projectiles rotate
	for _,v in NPC.iterate(695) do
		if v.despawnTimer > 0 then
			local data = v.data
			local config = NPC.config[v.id]
			local img = Graphics.sprites.npc[v.id].img
			Graphics.drawBox{
				texture = img,
				x = v.x + v.width/2,
				y = v.y + v.height/2,
				width = config.gfxwidth,
				height = config.gfxheight,
				sourceY = v.animationFrame * config.gfxheight,
				sourceHeight = config.gfxheight,
				sourceWidth = config.gfxwidth,
				sceneCoords = true,
				centered = true,
				priority = -45,
				rotation = (lunatime.tick() * 10 + (v.idx * 5)) * v.direction,
			}
			utils.hideNPC(v)
		end
	end
end

function onEvent(name)
	if name == "pinch_mode" then
		cannonTimer.value = 0
		cannonTimerOffset.value = 832
		local sec = Section(player.section)
		sec.effects.screenEffect = 1
	end
end