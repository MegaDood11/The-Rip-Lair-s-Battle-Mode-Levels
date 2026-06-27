local spawnzones = require("spawnzones")
local utils = require("npcs/npcutils")
local onlinePlay = require("scripts/onlinePlay")
local battleGeneral = require("scripts/battleGeneral")
local battleTimer = require("scripts/battleTimer")
local battleMessages = require("scripts/battleMessages")

local heartlessTimer = onlinePlay.createVariable("heartlessTimer","uint16",true,0)
local sideoftheTown = onlinePlay.createVariable("sideoftheTown","sint8",true,RNG.randomEntry{-1,1})
local hasSpawned = false
local heartlessSpawnPoint = {}

local sides = {
	[-1] = {
		effect = 789,
		npc = 919,
		xCoords = {
			[1] = -200000,
			[2] = 199872
		},
		yCoords = -200448,
	},
	[1] = {
		effect = 789,
		npc = 919,
		xCoords = {
			[1] = -196032,
			[2] = -196032
		},
		yCoords = RNG.randomInt(-200128,-200800),
	}
}

function onStart()

	if (battleGeneral.mode == battleGeneral.gameMode.STARS or battleGeneral.mode == battleGeneral.gameMode.STONE) then
		Audio.MusicChange(0, ("Twilight Town/Sinister Sundown.ogg"))
	else
		Audio.MusicChange(0, ("Twilight Town/The Encounter.ogg"))
	end

end

function onTick()

	heartlessTimer.value = heartlessTimer.value + 1
	local timer = heartlessTimer.value
	local side = sides[sideoftheTown.value]

	if timer >= 832 and timer <= 880 then
		if timer == 832 then SFX.play("heartless_spawn.wav") end
		if timer % 12 == 0 then
			sides[1].yCoords = RNG.randomInt(-200464,-200560)
			local e = Effect.spawn(249, RNG.randomInt(side.xCoords[1], side.xCoords[2]), side.yCoords)
			local n = Effect.spawn(side.effect, e.x, e.y)
			n.speedY = -8
		end

		if timer == 879 then
			for i = 1,6 do
				heartlessSpawnPoint[i] = RNG.randomInt(-200000, -196256)
			end
		end

	elseif timer >= 900 and timer <= 980 then
		if timer % 8 == 1 then
			SFX.play(26)
		end

		if timer == 900 then
			for i = 1,6 do
				Effect.spawn(752, heartlessSpawnPoint[i], -200160)
			end
			hasSpawned = true
		end

	else

		if timer == 1031 then
				SFX.play("heartless_text.wav")
				battleMessages.spawnStatusMessage("The Heartless has spawned around the town!", Color.fromHexRGBA(0xFFFFFFFF))
			for i = 1,6 do
				local v = NPC.spawn(side.npc, heartlessSpawnPoint[i], -200076, player.section, false)
				for i = 0, 3 do
					local e = Effect.spawn(NPC.config[v.id].deathEffect, v.x + v.width * 0.5, v.y + v.height * 0.25, i + 1, v.id, false)
					e.speedX = RNG.irandomEntry{-2,-1.5,-1,1,1.5,2}
					e.speedY = RNG.irandomEntry{-2,-1.5,-1,1,1.5,2}
				end
			end
		end

		if timer >= 1158 then
			heartlessTimer.value = 0
			sideoftheTown.value = sideoftheTown.value * -1
			hasSpawned = false
		end
	end
end


		