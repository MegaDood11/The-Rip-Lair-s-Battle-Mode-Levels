local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local onlinePlay,onlinePlayNPC

local battleStars = {}



battleStars.spawnTimeMin = lunatime.toTicks(12)
battleStars.spawnTimeMax = lunatime.toTicks(20)
battleStars.spawnTimeStart = lunatime.toTicks(12)

battleStars.spawnedNPC = nil
battleStars.lastSpawner = nil
battleStars.spawnTimer = 0

battleStars.spawnerBGOID = 832

local starSpawnCommand

function battleStars.onTickCollectable(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
    -- Don't let it despawn
    v.despawnTimer = math.max(100,v.despawnTimer)
end

local function canSpawnStars()
    return (not battleMessages.victoryActive and onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT)
end

local function findSpawnPosition()
    local spawners = {}

    for _,v in BGO.iterate(battleStars.spawnerBGOID) do
        if not v.isHidden and battleStars.lastSpawner ~= v then
            table.insert(spawners,v)
        end
    end

    if #spawners == 0 then
        for _,v in BGO.iterate(battleStars.spawnerBGOID) do
            if not v.isHidden then
                return v
            end
        end
    end

    return RNG.irandomEntry(spawners)
end

local function spawnStar()
    local spawner = findSpawnPosition()
    if spawner == nil then
        return
    end

    if battleStars.collectableSpawnID <= 0 then
        return
    end

    local v = NPC.spawn(battleStars.collectableSpawnID,spawner.x,spawner.y + 4,nil,false,true)

    v.layerName = spawner.layerName

    v.direction = DIR_LEFT
    v.spawnDirection = v.direction

    battleStars.lastSpawner = spawner
    battleStars.spawnedNPC = v

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


function battleStars.onStart()
    battleStars.spawnTimer = battleStars.spawnTimeStart
end

function battleStars.onTick()
    if not canSpawnStars() then
        return
    end

    if battleStars.spawnedNPC ~= nil then
        if not battleStars.spawnedNPC.isValid then
            battleStars.spawnTimer = RNG.randomInt(battleStars.spawnTimeMin,battleStars.spawnTimeMax)
            battleStars.spawnedNPC = nil
        end
    else
        battleStars.spawnTimer = math.max(0,battleStars.spawnTimer - 1)

        if battleStars.spawnTimer <= 0 then
            spawnStar()
        end

        --Text.print(battleStars.spawnTimer,32,32)
    end
end

function battleStars.onInitAPI()

    registerEvent(battleStars,"onStart")
    registerEvent(battleStars,"onTick")

	battleMessages = require("scripts/battleMessages")
    battleGeneral = require("scripts/battleGeneral")
    battleOptions = require("scripts/battleOptions")
    onlinePlay = require("scripts/onlinePlay")
    onlinePlayNPC = require("scripts/onlinePlay_npc")
	
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

            battleStars.spawnedNPC = npc
        end
    end
end


return battleStars