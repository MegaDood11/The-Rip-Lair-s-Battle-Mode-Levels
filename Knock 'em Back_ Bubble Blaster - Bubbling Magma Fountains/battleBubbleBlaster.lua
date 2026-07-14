local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local onlinePlay,onlinePlayNPC

local battleMessages,battlePlayer

local bubbleThing = {}

bubbleThing.initialSpawnBillyTimeMin = 3*8
bubbleThing.initialSpawnBillyTimeMax = 5*8

bubbleThing.initialSpawnGoldenBillyTimeMin = 96*8
bubbleThing.initialSpawnGoldenBillyTimeMax = 128*8

bubbleThing.billySpawnedNPC = nil
bubbleThing.billyLastSpawner = nil

bubbleThing.goldenBillySpawnedNPC = nil
bubbleThing.goldenBillyLastSpawner = nil

bubbleThing.spawnBillyTimer = 0

bubbleThing.spawnGoldenBillyTimer = 0
bubbleThing.spawnCount = 0


bubbleThing.billySpawnerBGOID = 954
bubbleThing.goldenBillySpawnerBGOID = 955

bubbleThing.spawnedNPCNormal = nil
bubbleThing.lastSpawnerNormal = nil

bubbleThing.spawnedNPCGold = nil
bubbleThing.lastSpawnerGold = nil

bubbleThing.billyID = 819
bubbleThing.goldenBillyID = 821

bubbleThing.maxNumber = 0

local starSpawnCommand

function bubbleThing.onTickCollectable(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
    -- Don't let it despawn
    v.despawnTimer = math.max(100,v.despawnTimer)
end

local function canSpawnStars()
    return (not battleMessages.victoryActive and onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT)
end

local function findSpawnPositionNormal()
    local spawners = {}

    for _,v in BGO.iterate(bubbleThing.billySpawnerBGOID) do
        if not v.isHidden and bubbleThing.lastSpawnerNormal ~= v then
            table.insert(spawners,v)
        end
    end

    if #spawners == 0 then
        for _,v in BGO.iterate(bubbleThing.billySpawnerBGOID) do
            if not v.isHidden then
                return v
            end
        end
    end

    return RNG.irandomEntry(spawners)
end

local function findSpawnPositionGold()
    local spawners = {}

    for _,v in BGO.iterate(bubbleThing.goldenBillySpawnerBGOID) do
        if not v.isHidden and bubbleThing.lastSpawnerGold ~= v then
            table.insert(spawners,v)
        end
    end

    if #spawners == 0 then
        for _,v in BGO.iterate(bubbleThing.goldenBillySpawnerBGOID) do
            if not v.isHidden then
                return v
            end
        end
    end

    return RNG.irandomEntry(spawners)
end

local function spawnStarNormal()
    local spawner = findSpawnPositionNormal()
    if spawner == nil then
        return
    end

    if bubbleThing.billyID <= 0 then
        return
    end
	
	local v = {}
	
	for i = 1,battlePlayer.getActivePlayerCount() do
		spawner = findSpawnPositionNormal()
		v[i] = NPC.spawn(bubbleThing.billyID,spawner.x,spawner.y + 4,nil,false,true)

		v[i].layerName = spawner.layerName

		v[i].direction = DIR_LEFT
		v[i].spawnDirection = v[i].direction

		bubbleThing.lastSpawnerNormal = spawner
		bubbleThing.spawnedNPCNormal[i] = v[i]
		bubbleThing.maxNumber = battlePlayer.getActivePlayerCount()

		-- Spawn an effect
		local e = Effect.spawn(10,v[i].x + v[i].width*0.5,v[i].y + v[i].height*0.5)

		e.x = e.x - e.width *0.5
		e.y = e.y - e.height*0.5

		-- Send a message 
		if onlinePlay.currentMode == onlinePlay.MODE_HOST then
			local data = onlinePlayNPC.getData(v[i])

			onlinePlayNPC.tryClaimNPC(v[i])

			starSpawnCommand:send(0, data.onlineUID)
		end
	end
end

local function spawnStarGold()
    local spawner = findSpawnPositionGold()
    if spawner == nil then
        return
    end

    if bubbleThing.goldenBillyID <= 0 then
        return
    end

	v = NPC.spawn(bubbleThing.goldenBillyID,spawner.x,spawner.y + 4,nil,false,true)

    v.layerName = spawner.layerName

    v.direction = DIR_LEFT
    v.spawnDirection = v.direction

    bubbleThing.lastSpawnerGold = spawner
    bubbleThing.spawnedNPCGold = v

    -- Spawn an effect
    local e = Effect.spawn(10,v.x + v.width*0.5,v.y + v.height*0.5)

    e.x = e.x - e.width *0.5
    e.y = e.y - e.height*0.5

    -- Send a message 
    if onlinePlay.currentMode == onlinePlay.MODE_HOST then
        local data = onlinePlayNPC.getData(v)

        onlinePlayNPC.tryClaimNPC(v)

        starSpawnCommand:send(0, data.onlineUID)
    end
end


function bubbleThing.onStart()
    bubbleThing.spawnBillyTimer = RNG.randomInt(bubbleThing.initialSpawnBillyTimeMin,bubbleThing.initialSpawnBillyTimeMax)
	bubbleThing.spawnGoldenBillyTimer = RNG.randomInt(bubbleThing.initialSpawnGoldenBillyTimeMin,bubbleThing.initialSpawnGoldenBillyTimeMax)
end

function bubbleThing.onNPCKill(e, v, r)
	if v.id ~= bubbleThing.billyID then return end
	bubbleThing.maxNumber = bubbleThing.maxNumber - 1
end

function bubbleThing.onTick()
    if not canSpawnStars() then
        return
    end
	
    if bubbleThing.maxNumber <= 0 then
        bubbleThing.spawnBillyTimer = math.max(0,bubbleThing.spawnBillyTimer - 1)

        if bubbleThing.spawnBillyTimer <= 0 then
			bubbleThing.spawnBillyTimer = RNG.randomInt(bubbleThing.initialSpawnBillyTimeMin,bubbleThing.initialSpawnBillyTimeMax)
			bubbleThing.spawnedNPCNormal = nil
			bubbleThing.spawnedNPCNormal = {}
            spawnStarNormal()
        end

    end
	 if bubbleThing.spawnedNPCGold ~= nil then
        if not bubbleThing.spawnedNPCGold.isValid then
            bubbleThing.spawnGoldenBillyTimer = RNG.randomInt(bubbleThing.initialSpawnGoldenBillyTimeMin,bubbleThing.initialSpawnGoldenBillyTimeMax)
            bubbleThing.spawnedNPCGold = nil
        end
    else
        bubbleThing.spawnGoldenBillyTimer = math.max(0,bubbleThing.spawnGoldenBillyTimer - 1)

        if bubbleThing.spawnGoldenBillyTimer <= 0 then
            spawnStarGold()
        end

        --Text.print(bubbleThing.spawnTimer,32,32)
    end
end

function bubbleThing.onInitAPI()

    registerEvent(bubbleThing,"onStart")
    registerEvent(bubbleThing,"onTick")
	registerEvent(bubbleThing,"onNPCKill")

	battleMessages = require("scripts/battleMessages")
    battleGeneral = require("scripts/battleGeneral")
    battleOptions = require("scripts/battleOptions")
    onlinePlay = require("scripts/onlinePlay")
    onlinePlayNPC = require("scripts/onlinePlay_npc")
	battlePlayer = require("scripts/battlePlayer")
	
    starSpawnCommand = onlinePlay.createCommand("battle_clayworkThing_spawn",onlinePlay.IMPORTANCE_MAJOR)

    function starSpawnCommand.onReceive(sourcePlayerIdx, onlineUID)
        if onlinePlay.currentMode == onlinePlay.MODE_HOST or sourcePlayerIdx ~= onlinePlay.hostPlayerIdx then
            return
        end

        local npc = onlinePlayNPC.getNPCFromUID(onlineUID)

        if npc ~= nil and npc.isValid then
            -- Spawn an effect
            local e = Effect.spawn(10,npc.x + npc.width*0.5,npc.y + npc.height*0.5)
    
            e.x = e.x - e.width *0.5
            e.y = e.y - e.height*0.5
			
			if npc.id == bubbleThing.goldenBillyID then bubbleThing.spawnedNPCGold = npc end
        end
    end
end


return bubbleThing