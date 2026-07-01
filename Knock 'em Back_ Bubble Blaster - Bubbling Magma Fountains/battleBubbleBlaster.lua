local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local textFiles = require("scripts/textFiles")
local playerstun = require("playerstun")

local battleMessages,battlePlayer
local onlinePlay,onlinePlayNPC,onlinePlayPlayers

local battleStone = {}


battleStone.initialSpawnBillyTimeMin = 3*8
battleStone.initialSpawnBillyTimeMax = 5*8

battleStone.initialSpawnGoldenBillyTimeMin = 96*8
battleStone.initialSpawnGoldenBillyTimeMax = 128*8

battleStone.billySpawnedNPC = nil
battleStone.billyLastSpawner = nil

battleStone.goldenBillySpawnedNPC = nil
battleStone.goldenBillyLastSpawner = nil

battleStone.spawnBillyTimer = 0

battleStone.spawnGoldenBillyTimer = 0
battleStone.spawnCount = 0


battleStone.billySpawnerBGOID = 954
battleStone.goldenBillySpawnerBGOID = 955

battleStone.billyID = 819
battleStone.goldenBillyID = 821


local billySpawnCommand
local goldenBillySpawnCommand


local function getTotalDistanceToPlayers(x,y)
    local totalDistance = 0

    for _,p in ipairs(battlePlayer.getActivePlayers()) do
        local distX = p.x + p.width*0.5 - x
        local distY = p.y + p.height*0.5 - y

        totalDistance = totalDistance + math.sqrt(distX*distX + distY*distY)
    end

    return totalDistance
end

local function sortSpawners(bgoA,bgoB)
    return (getTotalDistanceToPlayers(bgoA.x + bgoA.width*0.5,bgoA.y + bgoA.height*0.5) > getTotalDistanceToPlayers(bgoB.x + bgoB.width*0.5,bgoB.y + bgoB.height*0.5))
end

local function findSpawnBillyPosition()
    local spawners = {}

    for _,v in BGO.iterate(battleStone.billySpawnerBGOID) do
        if not v.isHidden then
            table.insert(spawners,v)
        end
    end

    table.sort(spawners,sortSpawners)

    return spawners
end
local function findSpawnGoldenBillyPosition()
    local spawners = {}

    for _,v in BGO.iterate(battleStone.goldenBillySpawnerBGOID) do
        if not v.isHidden then
            table.insert(spawners,v)
        end
    end

    table.sort(spawners,sortSpawners)

    return spawners
end

local function spawnBilly()
    local spawners = findSpawnBillyPosition()
    if #spawners == 0 then
        return
    end

    if battleStone.billyID <= 0 then
        return
    end

    battleStone.spawnCount = math.max(3, math.ceil(battlePlayer.getActivePlayerCount() * 0.5))

	for i = 1, battleStone.spawnCount do
        local spawner = spawners[(i - 1)%#spawners + 1]

		local v = NPC.spawn(battleStone.billyID, spawner.x + spawner.width*0.5, spawner.y + spawner.height*0.5, nil, false, true)

		v.data.initialized = false
	
		v.layerName = "Spawned NPCs"
	
		v.direction = DIR_LEFT
		v.spawnDirection = v.direction

		battleStone.billySpawnedNPC = v
		battleStone.billyLastSpawner = spawner
	
		-- Spawn an effect
		local e = Effect.spawn(10,v.x + v.width*0.5,v.y + v.height*0.5)
	
		e.x = e.x - e.width *0.5
		e.y = e.y - e.height*0.5	
	end

    -- Send a message 
    if onlinePlay.currentMode == onlinePlay.MODE_HOST then
        local data = onlinePlayNPC.getData(v)

        onlinePlayNPC.tryClaimNPC(v)

        billySpawnCommand:send(0, data.onlineUID)
    end
end

local function spawnGoldenBilly()
    local spawners = findSpawnGoldenBillyPosition()
    if #spawners == 0 then
        return
    end

    if battleStone.goldenBillyID <= 0 then
        return
    end

    battleStone.spawnCount = math.max(1, math.ceil(battlePlayer.getActivePlayerCount() * 0.5))

	for i = 1, battleStone.spawnCount do
        local spawner = spawners[(i - 1)%#spawners + 1]

		local v = NPC.spawn(battleStone.goldenBillyID, spawner.x + spawner.width*0.5, spawner.y + spawner.height*0.5, nil, false, true)

		v.data.initialized = false
	
		v.layerName = "Spawned NPCs"
	
		v.direction = DIR_LEFT
		v.spawnDirection = v.direction

		battleStone.goldenBillySpawnedNPC = v
		battleStone.goldenBillyLastSpawner = spawner
	
		-- Spawn an effect
		local e = Effect.spawn(10,v.x + v.width*0.5,v.y + v.height*0.5)
	
		e.x = e.x - e.width *0.5
		e.y = e.y - e.height*0.5	
	end

    -- Send a message 
    if onlinePlay.currentMode == onlinePlay.MODE_HOST then
        local data = onlinePlayNPC.getData(v)

        onlinePlayNPC.tryClaimNPC(v)

        goldenBillySpawnCommand:send(0, data.onlineUID)
    end
end

function battleStone.onStart()
    battleStone.spawnBillyTimer = RNG.random(battleStone.initialSpawnBillyTimeMin, battleStone.initialSpawnBillyTimeMax)
    battleStone.spawnGoldenBillyTimer = RNG.random(battleStone.initialSpawnGoldenBillyTimeMin, battleStone.initialSpawnGoldenBillyTimeMax)
end

function battleStone.onTick()
    -- Spawning
    if not battleMessages.victoryActive and onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT then
		if battleStone.billySpawnedNPC ~= nil then
			if not battleStone.billySpawnedNPC.isValid then
				battleStone.spawnBillyTimer = RNG.random(battleStone.initialSpawnBillyTimeMin, battleStone.initialSpawnBillyTimeMax)
				battleStone.billySpawnedNPC = nil
			end
		else
			battleStone.spawnBillyTimer = math.max(0,battleStone.spawnBillyTimer - 1)
	
			if battleStone.spawnBillyTimer <= 0 then
				spawnBilly()
			end
		end
	end
    if not battleMessages.victoryActive and onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT then
		if battleStone.goldenBillySpawnedNPC ~= nil then
			if not battleStone.goldenBillySpawnedNPC.isValid then
				battleStone.spawnGoldenBillyTimer = RNG.random(battleStone.initialSpawnGoldenBillyTimeMin, battleStone.initialSpawnGoldenBillyTimeMax)
				battleStone.goldenBillySpawnedNPC = nil
			end
		else
			battleStone.spawnGoldenBillyTimer = math.max(0,battleStone.spawnGoldenBillyTimer - 1)
	
			if battleStone.spawnGoldenBillyTimer <= 0 then
				spawnGoldenBilly()
			end
		end
	end
	
	--Text.print(getWeightedRandomSpawnGoldenBilly(), 100, 100)
end


function battleStone.onInitAPI()
    registerEvent(battleStone,"onTick")
    registerEvent(battleStone,"onStart")

    battleMessages = require("scripts/battleMessages")
    battlePlayer = require("scripts/battlePlayer")
    onlinePlay = require("scripts/onlinePlay")
	onlinePlayNPC = require("scripts/onlinePlay_npc")
	onlinePlayPlayers = require("scripts/onlinePlay_players")


    billySpawnCommand = onlinePlay.createCommand("billy_spawn", onlinePlay.IMPORTANCE_MAJOR)

    function billySpawnCommand.onReceive(sourcePlayerIdx, onlineUID)
        if onlinePlay.currentMode == onlinePlay.MODE_HOST or sourcePlayerIdx ~= onlinePlay.hostPlayerIdx then
            return
        end

        local npc = onlinePlayNPC.getNPCFromUID(onlineUID)

        if npc ~= nil and npc.isValid then
            -- Spawn an effect
            local e = Effect.spawn(10,npc.x + npc.width*0.5,npc.y + npc.height*0.5)
    
            e.x = e.x - e.width *0.5
            e.y = e.y - e.height*0.5

            battleStone.billySpawnedNPC = npc
        end
    end
    goldenBillySpawnCommand = onlinePlay.createCommand("golden_billy_spawn", onlinePlay.IMPORTANCE_MAJOR)

    function goldenBillySpawnCommand.onReceive(sourcePlayerIdx, onlineUID)
        if onlinePlay.currentMode == onlinePlay.MODE_HOST or sourcePlayerIdx ~= onlinePlay.hostPlayerIdx then
            return
        end

        local npc = onlinePlayNPC.getNPCFromUID(onlineUID)

        if npc ~= nil and npc.isValid then
            -- Spawn an effect
            local e = Effect.spawn(10,npc.x + npc.width*0.5,npc.y + npc.height*0.5)
    
            e.x = e.x - e.width *0.5
            e.y = e.y - e.height*0.5

            battleStone.goldenBillySpawnedNPC = npc
        end
    end
end


return battleStone