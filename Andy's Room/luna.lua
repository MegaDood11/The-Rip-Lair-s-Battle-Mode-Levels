local blockRespawning = require("scripts/blockRespawning")
local onlinePlay = require("scripts/onlinePlay")
local battleGeneral = require("scripts/battleGeneral")
blockRespawning.defaultRespawnTime = 32*32

local randomTable = onlinePlay.createVariable("randomTable","uint16",true,0)
local randomSpawn = onlinePlay.createVariable("randomSpawn","uint16",true,1)
local cooldown = onlinePlay.createVariable("cooldown","uint16",true,0)

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