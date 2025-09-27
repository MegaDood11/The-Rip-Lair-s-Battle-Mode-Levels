local battlePlayer = require("scripts/battlePlayer")
local faller = require("faller")
local areaNames = require("areaNames")

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")
battleTimer = require("scripts/battleTimer")

local blockRespawning = require("scripts/blockRespawning")
blockRespawning.defaultRespawnTime = 24*30

local randomSection = onlinePlay.createVariable("randomSection","uint16",true,RNG.randomInt(0,64))
local thing = onlinePlay.createVariable("thing","uint16",true,0)

if onlinePlay.currentMode == onlinePlay.MODE_CLIENT then
	randomSection.value = RNG.randomInt(0,64)
end

local sectionMusic = {
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{4, 6},
	6,
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{1, 5},
	47,
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	47,
	6,
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	6,
	RNG.irandomEntry{1, 5},
	6,
	RNG.irandomEntry{1, 5},
	6,
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	6,
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	6,
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{4, 6},
	6,
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{4, 6},
	47,
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{4, 6},
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
	47,
	RNG.irandomEntry{1, 5},
	RNG.irandomEntry{1, 5},
} 

local sectionName = {
[1] = "2skyflight",
[2] = "3blockforts",
[3] = "4highabove",
[4] = "5fall",
[5] = "Above the clouds",
[6] = "Alinos gate",
[7] = "Arcterra gate",
[8] = "Bounce2lava",
[9] = "Dungeon Party",
[10] = "Hello world",
[11] = "Icecap",
[12] = "Mountains",
[13] = "Blockfort",
[14] = "Eighth Platform",
[15] = "Zelda 1 - First Quest Level 2",
[16] = "Indoor",
[17] = "King of the Hills",
[18] = "Pillars of glory",
[19] = "Greden",
[20] = "Hanging Cactus Gardens",
[21] = "1-3",
[22] = "Azul Montana",
[23] = "Begging for sumo again",
[24] = "Classicka",
[25] = "Deep Water Mace",
[26] = "Dottedplus",
[27] = "1986",
[28] = "Battleblockarea",
[29] = "Divine intervention",
[30] = "Affe",
[31] = "Big Tree",
[32] = "Block! Block!",
[33] = "Chainlink",
[34] = "Greeny",
[35] = "Rubber Room",
[36] = "Death From Above",
[37] = "Field day",
[38] = "Death to iggy",
[39] = "Mushroom Kingdom",
[40] = "Sky realm",
[41] = "Classicon",
[42] = "Ghosthouse",
[43] = "Gold",
[44] = "Islands of Questionable Support",
[45] = "What",
[46] = "Symmetrical",
[47] = "Lockout",
[48] = "Piemont",
[49] = "Yoshi island",
[50] = "Wood Pit",
[51] = "Stairway",
[52] = "Thecourtyard",
[53] = "Up In The Hills",
[54] = "The pit",
[55] = "Watery Day",
[56] = "Floating Cubes",
[57] = "Storage Building",
[58] = "Double-t",
[59] = "Mushroom valley",
[60] = "Cave",
[61] = "Bottle",
[62] = "Traumatic Plains",
[63] = "Coolnights",
[64] = "Suspended Craziness",
[65] = "Wacky Woods",
}

local sectionBackground = {
[1] = 1,
[2] = 34,
[3] = 2,
[4] = 1,
[5] = 1,
[6] = 31,
[7] = 65,
[8] = 20,
[9] = 25,
[10] = 1,
[11] = 35,
[12] = 34,
[13] = 1,
[14] = 1,
[15] = 39,
[16] = 1,
[17] = 49,
[18] = 30,
[19] = 34,
[20] = 16,
[21] = 64,
[22] = 45,
[23] = 1,
[24] = 1,
[25] = 55,
[26] = 46,
[27] = 43,
[28] = 4,
[29] = 13,
[30] = 34,
[31] = 5,
[32] = 1,
[33] = 15,
[34] = 1,
[35] = 15,
[36] = 34,
[37] = 71,
[38] = 15,
[39] = 41,
[40] = 13,
[41] = 20,
[42] = 18,
[43] = 16,
[44] = 64,
[45] = 34,
[46] = 2,
[47] = 36,
[48] = 2,
[49] = 43,
[50] = 72,
[51] = 50,
[52] = 46,
[53] = 43,
[54] = 30,
[55] = 55,
[56] = 22,
[57] = 38,
[58] = 1,
[59] = 41,
[60] = 30,
[61] = 1,
[62] = 16,
[63] = 49,
[64] = 35,
[65] = 12,
}

local list = {159, 777, 4, 5, 90}

--Harm players who are hit from below
function onBlockHit(eventObj,v,fromTop,playerObj)
    for _,p in ipairs(Player.getIntersecting(v.x, v.y - 4, v.x + v.width, v.y)) do
		for _,list in ipairs(list) do
			if (p.isValid and battleGeneral.mode == 0) and not Colliders.downSlash(p,v) and v.id == list and p.y < v.y - 16 then
				battlePlayer.harmPlayer(p,battlePlayer.HARM_TYPE.NORMAL)
			end
		end
	end
end

local cubeMoveTime = 1024
local cubeMoveDistance = 256

local spinMoveTime = 512
local spinMoveDistance = 160

local cubeMoveTimer = onlinePlay.createVariable("cubeMoveTimer","uint16",true,0)
local spinMoveTimer = onlinePlay.createVariable("spinMoveTimer","uint16",true,0)
local cubeLayer
local spinLayer

function onStart()
    cubeLayer = Layer.get("Cubes")
	spinLayer = Layer.get("Spin")
end

function onTick()
    if cubeLayer ~= nil then
        cubeLayer.pauseDuringEffect = false

        if not cubeLayer:isPaused() then
            local time = cubeMoveTime/math.pi/2

            cubeLayer.speedY = math.sin(cubeMoveTimer.value/time)*cubeMoveDistance/time*0.5
            cubeLayer.pauseDuringEffect = false
            
            cubeMoveTimer.value = (cubeMoveTimer.value + 1) % cubeMoveTime
        end
    end
	
	if spinLayer ~= nil then
        spinLayer.pauseDuringEffect = false

        if not spinLayer:isPaused() then
            local time = spinMoveTime/math.pi/2

			spinLayer.speedX = math.sin(-spinMoveTimer.value/time)*spinMoveDistance/time*0.5
            spinLayer.speedY = math.cos(-spinMoveTimer.value/time)*spinMoveDistance/time*0.5
            spinLayer.pauseDuringEffect = false
            
            spinMoveTimer.value = (spinMoveTimer.value + 1) % spinMoveTime
        end
    end
end

function onDraw()
	--Load the level into the game
	if not Misc.isPaused() then
		thing.value = thing.value + 1
		if onlinePlay.currentMode == onlinePlay.MODE_CLIENT then
			if thing.value == 2 then
				Audio.MusicChange(0, sectionMusic[randomSection.value + 1])
				Layer.get(tostring(randomSection.value)):show(true)
				Section(0).backgroundID = sectionBackground[randomSection.value + 1]
				areaNames.show(sectionName[randomSection.value + 1])
			end
		else
			if thing.value == 1 then
				Audio.MusicChange(0, sectionMusic[randomSection.value + 1])
				Layer.get(tostring(randomSection.value)):show(true)
				
				if randomSection.value == 16 then
					Layer.get("Platform1"):show(true)
					Layer.get("Platform2"):show(true)
					Layer.get("Platform3"):show(true)
				end
				
				if randomSection.value == 38 then
					Layer.get("Platform4"):show(true)
				end
				
				if randomSection.value == 52 then
					Layer.get("Platform5"):show(true)
					Layer.get("Platform6"):show(true)
				end
				
				if randomSection.value == 55 then
					Layer.get("Cubes"):show(true)
				end
				
				if randomSection.value == 58 then
					Layer.get("Spin"):show(true)
				end
				
				if randomSection.value == 62 then
					Layer.get("Platform7"):show(true)
				end
				
				Section(0).backgroundID = sectionBackground[randomSection.value + 1]
				areaNames.show(sectionName[randomSection.value + 1])
			end
			
			if lunatime.tick() % 1920 == 0 then
				Layer.get(tostring(randomSection.value)):show(true)
			end
		end
		
		--Bump the side of note blocks, for added chaos
		for _,v in ipairs(Block.get(55)) do
			for _,p in ipairs(Player.getIntersecting(v.x - 2, v.y + 8, v.x + v.width + 2, v.y + v.height - 8)) do
				if not v.isHidden and p.deathTimer <= 0 then
					v:hit(true)
					p.speedX = 4 * math.sign(p.x - v.x + v.width * 0.5)
					SFX.play(3)
				end
			end
		end
	end
end