local npcManager = require("npcManager")

local battleGeneral,battlePlayer,battleStars,battleCamera
local onlinePlay,onlinePlayNPC,onlinePlayPlayers

local battleItems = {}


battleItems.ITEMS_TYPE = {
    DISABLED = 0,
    NORMAL = 1,
    POWERUPS_ONLY = 2,
}

battleItems.GRANT_STATE = {
    INACTIVE = 0,
    DELAY = 1,
    PREVIEW = 2,
}

battleItems.allCoinsSound = Misc.resolveSoundFile("resources/allCoins")
battleItems.previewSound = 11

battleItems.delayDuration = 48
battleItems.previewDuration = 64


battleItems.itemSettingsMap = {}
battleItems.itemIDList = {}
battleItems.itemCooldowns = {}


local randomItemRequestCommand
local randomItemResponseCommand
local itemPreviewCommand
local itemFinishedCommand


function battleItems.registerItem(npcID,settings)
    if battleItems.itemSettingsMap[npcID] == nil then
        table.insert(battleItems.itemIDList,npcID)
    end

    battleItems.itemSettingsMap[npcID] = {
        minPlacement = settings.minPlacement or 0,
        maxPlacement = settings.maxPlacement or 1,

        weightMinPlacement = settings.weightMinPlacement or settings.weight or 1,
        weightMaxPlacement = settings.weightMaxPlacement or settings.weight or 1,

        cooldown = settings.cooldown or 0,
        isPowerup = settings.isPowerup or false,

        blacklistedCharacterMap = settings.blacklistedCharacterMap or {},
        blacklistedPowerupMap = settings.blacklistedPowerupMap or {},

        spawnFunc = settings.spawnFunc,
    }
    battleItems.itemCooldowns[npcID] = 0
end

function battleItems.deregisterItem(npcID)
    local index = table.ifind(battleItems.itemIDList,npcID)

    if index ~= nil then
        table.remove(battleItems.itemIDList,index)
    end

    battleItems.npcSettingsMap[npcID] = nil
    battleItems.itemCooldowns[npcID] = nil
end


function battleItems.initPlacementFunctions()
    -- These functions determine the "placing" of a player, used for item distribution.
    -- 1 is first place, 0 is last.
    battleItems.getPlacementFuncs = {}

    battleItems.getPlacementFuncs[battleGeneral.gameMode.ARENA] = function(p)
        -- Determine the largest/smallest number of lives
        local leastLifeCount = math.huge
        local mostLifeCount = 0

        for _,p in ipairs(battlePlayer.getActivePlayers()) do
            local data = battlePlayer.getPlayerData(p)

            leastLifeCount = math.min(leastLifeCount,data.lives)
            mostLifeCount = math.max(mostLifeCount,data.lives)
        end

        if mostLifeCount == leastLifeCount then
            return 0.75
        end

        if mostLifeCount <= 1 then
            return 0.25
        end

        -- Determine how this player places based on that their count
        local data = battlePlayer.getPlayerData(p)

        return math.invlerp(1,mostLifeCount,data.lives)
    end

    battleItems.getPlacementFuncs[battleGeneral.gameMode.STARS] = function(p)
        -- Determine the largest/smallest number of stars
        local leastStarCount = math.huge
        local mostStarCount = 0

        for _,p in ipairs(battlePlayer.getActivePlayers()) do
            local data = battlePlayer.getPlayerData(p)

            leastStarCount = math.min(leastStarCount,data.stars)
            mostStarCount = math.max(mostStarCount,data.stars)
        end

        if mostStarCount == leastStarCount then
            return 0.75
        end

        -- Determine how this player places based on that their count
        local data = battlePlayer.getPlayerData(p)

        return math.invlerp(0,mostStarCount,data.stars)
    end

    battleItems.getPlacementFuncs[battleGeneral.gameMode.STONE] = function(p)
        -- Determine the largest/smallest number of points
        local leastPointCount = math.huge
        local mostPointCount = 0

        for _,p in ipairs(battlePlayer.getActivePlayers()) do
            local data = battlePlayer.getPlayerData(p)

            leastPointCount = math.min(leastPointCount,data.points)
            mostPointCount = math.max(mostPointCount,data.points)
        end

        if mostPointCount == leastPointCount then
            return 0.75
        end

        -- Determine how this player places based on that their count
        local data = battlePlayer.getPlayerData(p)

        return math.invlerp(0,mostPointCount,data.points)
    end
end


function battleItems.registerDefaultItems()
    -- Mushroom
    battleItems.registerItem(9,{
        blacklistedPowerupMap = table.map{
            PLAYER_BIG, PLAYER_FIREFLOWER, PLAYER_ICE, PLAYER_LEAF,
            PLAYER_TANOOKIE, PLAYER_HAMMER,
        },
        minPlacement = 0.5,
        maxPlacement = 1,
        weightMinPlacement = 2,
        weightMaxPlacement = 8,
        isPowerup = true,
    })

    -- Fire/ice flower
    battleItems.registerItem(14,{
        blacklistedPowerupMap = table.map{
            PLAYER_FIREFLOWER, PLAYER_TANOOKIE, PLAYER_HAMMER,
        },
        minPlacement = 0,
        maxPlacement = 1,
        weightMinPlacement = 4,
        weightMaxPlacement = 2,
        isPowerup = true,
    })
    battleItems.registerItem(264,{
        blacklistedPowerupMap = table.map{
            PLAYER_ICE, PLAYER_TANOOKIE, PLAYER_HAMMER,
        },
        minPlacement = 0,
        maxPlacement = 0.5,
        weightMinPlacement = 3,
        weightMaxPlacement = 1,
        isPowerup = true,
    })

    -- Tanooki/Hammer suit
    battleItems.registerItem(169,{
        blacklistedPowerupMap = table.map{
            PLAYER_SMALL, PLAYER_TANOOKIE,
        },
        minPlacement = 0,
        maxPlacement = 0.2,
        weightMinPlacement = 2,
        weightMaxPlacement = 1,
        isPowerup = true,
    })
    battleItems.registerItem(170,{
        blacklistedPowerupMap = table.map{
            PLAYER_SMALL, PLAYER_HAMMER,
        },
        minPlacement = 0,
        maxPlacement = 0.2,
        weightMinPlacement = 2,
        weightMaxPlacement = 1,
        isPowerup = true,
    })

    -- Blue brick
    battleItems.registerItem(134,{
        spawnFunc = function(p,n)
            -- Set ai1 instead of projectile state
            if n:mem(0x136,FIELD_BOOL) then
                n:mem(0x136,FIELD_BOOL,false)
                n.ai1 = 1
            end
        end,
        minPlacement = 0.5,
        maxPlacement = 1,
        weightMinPlacement = 2,
        weightMaxPlacement = 2,
    })
	
		battleItems.registerItem(768,{
        blacklistedPowerupMap = table.map{
            PLAYER_ICE, PLAYER_TANOOKIE, PLAYER_HAMMER,
        },
        minPlacement = 0.5,
        maxPlacement = 1,
        weightMinPlacement = 2,
        weightMaxPlacement = 2,
    })
	
		battleItems.registerItem(769,{
        blacklistedPowerupMap = table.map{
            PLAYER_ICE, PLAYER_TANOOKIE, PLAYER_HAMMER,
        },
        minPlacement = 0.5,
        maxPlacement = 1,
        weightMinPlacement = 2,
        weightMaxPlacement = 2,
    })
	
		battleItems.registerItem(770,{
        blacklistedPowerupMap = table.map{
            PLAYER_ICE, PLAYER_TANOOKIE, PLAYER_HAMMER,
        },
        minPlacement = 0.5,
        maxPlacement = 1,
        weightMinPlacement = 2,
        weightMaxPlacement = 2,
    })
	
		battleItems.registerItem(772,{
        blacklistedPowerupMap = table.map{
            PLAYER_ICE, PLAYER_TANOOKIE, PLAYER_HAMMER,
        },
        minPlacement = 0.5,
        maxPlacement = 1,
        weightMinPlacement = 2,
        weightMaxPlacement = 2,
    })

    -- Shell
    battleItems.registerItem(113,{
        minPlacement = 0,
        maxPlacement = 1,
        weightMinPlacement = 2,
        weightMaxPlacement = 1,
    })

    -- Star
    battleItems.registerItem(293,{
        blacklistedCharacterMap = table.map{
            CHARACTER_LINK,
        },
        blacklistedPowerupMap = table.map{
            PLAYER_HAMMER, PLAYER_TANOOKIE,
        },
        minPlacement = 0,
        maxPlacement = 0.3,
        weightMinPlacement = 4,
        weightMaxPlacement = 1,

        cooldown = lunatime.toTicks(75),
    })

    -- ? Mushroom
    battleItems.registerItem(952,{
        minPlacement = 0,
        maxPlacement = 0.5,
        weightMinPlacement = 3,
        weightMaxPlacement = 1,

        cooldown = lunatime.toTicks(45),
    })

    -- Boo mushroom
    battleItems.registerItem(957,{
        minPlacement = 0,
        maxPlacement = 0.75,
        weightMinPlacement = 5,
        weightMaxPlacement = 2,

        cooldown = lunatime.toTicks(30),
    })

    -- First-Place Phanto
    battleItems.registerItem(958,{
        blacklistedCharacterMap = table.map{
            CHARACTER_LINK,
        },

        minPlacement = 0,
        maxPlacement = 0.75,
        weightMinPlacement = 8,
        weightMaxPlacement = 2,

        cooldown = lunatime.toTicks(30),
    })

    -- Billy gun
    battleItems.registerItem(22,{
        spawnFunc = function(p,n)
            -- Set up settings
            local settings = n.data._settings

            settings.timer = 24
            settings.shots = 20
        end,

        minPlacement = 0,
        maxPlacement = 0.5,
        weightMinPlacement = 3,
        weightMaxPlacement = 0,

        cooldown = lunatime.toTicks(25),
    })
end


function battleItems.getPlayerPlacement(p)
    if not battlePlayer.getPlayerIsActive(p) then
        return 1
    end

    if battleItems.getPlacementFuncs[battleGeneral.mode] == nil then
        return 0.5
    end

    return battleItems.getPlacementFuncs[battleGeneral.mode](p) or 0.5
end


local function canGetItem(p,placementValue,npcID)
    local settings = battleItems.itemSettingsMap[npcID]

    if battleItems.itemCooldowns[npcID] > 0 then
        return false
    end

    if placementValue < settings.minPlacement or placementValue > settings.maxPlacement then
        return false
    end

    if settings.blacklistedCharacterMap[p.character] or settings.blacklistedPowerupMap[p.powerup] then
        return false
    end

    local modeRuleset = battleOptions.getModeRuleset()

    if modeRuleset.itemsType == battleItems.ITEMS_TYPE.POWERUPS_ONLY and not settings.isPowerup then
        return false
    end

    return true
end

local function getWeightedItemList(p,placementValue)
    local idList = {}
    
    for _,npcID in ipairs(battleItems.itemIDList) do
        if canGetItem(p,placementValue,npcID) then
            local settings = battleItems.itemSettingsMap[npcID]

            local placementLerp = math.invlerp(settings.minPlacement,settings.maxPlacement,placementValue)
            local weight = math.lerp(settings.weightMinPlacement,settings.weightMaxPlacement,placementLerp)

            weight = math.floor(weight + 0.5)

            for i = 1,weight do
                table.insert(idList,npcID)
            end
        end
    end

    return idList
end

function battleItems.decideRandomItem(p)
    local placementValue = battleItems.getPlayerPlacement(p)

    local idList = getWeightedItemList(p,placementValue)
    local npcID = RNG.irandomEntry(idList) or 9

    local settings = battleItems.itemSettingsMap[npcID]

    battleItems.itemCooldowns[npcID] = settings.cooldown

    return npcID
end


function battleItems.getCoinsForItem()
    local modeRuleset = battleOptions.getModeRuleset()

    if modeRuleset.coinsForItem == nil or modeRuleset.itemsType == battleItems.ITEMS_TYPE.DISABLED then
        return 0
    end

    return modeRuleset.coinsForItem
end

function battleItems.playerHasReserveBox(p)
    local fullRuleset = battleOptions.getFullRuleset()

    if not fullRuleset.general.reserveBoxEnabled then
        return false
    end

    return (p.character == CHARACTER_MARIO or p.character == CHARACTER_LUIGI)
end


function battleItems.grantItem(p,npcID)
    if not onlinePlayPlayers.ownsPlayer(p) then
        return
    end

    local data = battlePlayer.getPlayerData(p)

    if data.itemGrantState ~= battleItems.GRANT_STATE.INACTIVE then
        return
    end

    data.itemGrantState = battleItems.GRANT_STATE.DELAY
    data.itemGrantTimer = 0

    data.itemGrantID = npcID or 0
    data.itemGrantIsFromReserve = false

    SFX.play(battleItems.allCoinsSound)

    if data.itemGrantID == 0 then
        if onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT then
            -- Pick a random item
            data.itemGrantID = battleItems.decideRandomItem(p)
        else
            -- ASk the host to give us a random item
            randomItemRequestCommand:send(onlinePlay.hostPlayerIdx)
        end
    end
end

function battleItems.dropReserveItem(p,npcID)
    if not onlinePlayPlayers.ownsPlayer(p) then
        return
    end

    local data = battlePlayer.getPlayerData(p)

    if data.itemGrantState ~= battleItems.GRANT_STATE.INACTIVE then
        return
    end

    data.itemGrantState = battleItems.GRANT_STATE.PREVIEW
    data.itemGrantTimer = 0

    data.itemGrantID = npcID
    data.itemGrantIsFromReserve = true

    if onlinePlayPlayers.canMakeSound(p) then
        SFX.play(battleItems.previewSound)
    end

    -- Ask the host to give us a random item
    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        itemPreviewCommand:send(0, data.itemGrantID,data.itemGrantIsFromReserve)
    end
end


function battleItems.addCoins(p,amount,effectX,effectY)
    if not onlinePlayPlayers.ownsPlayer(p) then
        return
    end

    amount = amount or 1
    effectX = effectX or (p.x + p.width*0.5)
    effectY = effectY or (p.y - 16)

    if amount <= 0 then
        return
    end
    
    local coinsForItem = battleItems.getCoinsForItem()
    if coinsForItem <= 0 then
        return
    end

    local data = battlePlayer.getPlayerData(p)

    if data.coins >= coinsForItem then
        return
    end

    if battleItems.coinAmountModifierFunc ~= nil then
        amount = battleItems.coinAmountModifierFunc(p,amount)
    end

    data.coins = math.min(coinsForItem,data.coins + amount)
    battleGeneral.spawnNumberEffects(951,effectX,effectY,data.coins)

    if data.coins >= coinsForItem and data.itemGrantState == battleItems.GRANT_STATE.INACTIVE then
        data.itemGrantIsFromCoins = true
        battleItems.grantItem(p)
    end
end


function battleItems.onPostNPCCollect(v,p)
    local config = NPC.config[v.id]

    if not config.iscoin then
        return
    end

    if not onlinePlayPlayers.ownsPlayer(p) then
        return
    end

    battleItems.addCoins(p,1,v.x + v.width*0.5,v.y + v.height*0.5 + 4)
end


local coinSpawnCharacters = table.map{CHARACTER_LUIGI,CHARACTER_TOAD,CHARACTER_LINK}

function battleItems.onPostBlockHit(block,fromTop,playerObj)
    if playerObj == nil or not onlinePlayPlayers.ownsPlayer(playerObj) then
        return
    end

    if block.contentID > 0 and block.contentID < 100 and not coinSpawnCharacters[playerObj.character] then
        battleItems.addCoins(playerObj,1,block.x + block.width*0.5,block.y - 16)
    end
end


local function getItemSpawnPosition(p,npcID)
    local data = battlePlayer.getPlayerData(p)

    local x = p.x + p.width*0.5
    local y = p.y

    if data.itemGrantIsFromReserve then
        y = y - 128
    else
        y = y - 64
    end

    -- Prevent it from going off the top of the section
    y = math.max(y,p.sectionObj.boundary.top + NPC.config[npcID].height*0.5 + 8)

    return x,y
end

local function spawnItem(p)
    local data = battlePlayer.getPlayerData(p)

    local settings = battleItems.itemSettingsMap[data.itemGrantID]

    local x,y = getItemSpawnPosition(p,data.itemGrantID)
    local n = NPC.spawn(data.itemGrantID,x,y,p.section,false,true)

    n.direction = DIR_LEFT

    if p.character == CHARACTER_LINK and not NPC.COLLECTIBLE_MAP[n.id] then
        n:mem(0x136,FIELD_BOOL,true)
        n:mem(0x12E,FIELD_WORD,64)
        n:mem(0x130,FIELD_WORD,p.idx)
    else
        n:mem(0x138,FIELD_WORD,2)
    end

    if settings ~= nil and settings.spawnFunc ~= nil then
        settings.spawnFunc(p,n)
    end

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        onlinePlayNPC.tryClaimNPC(n)
    end

    return n
end


local function handleItemGranting(p)
    local data = battlePlayer.getPlayerData(p)

    if data.itemGrantState == battleItems.GRANT_STATE.INACTIVE then
        return
    end

    if data.itemGrantState == battleItems.GRANT_STATE.DELAY then
        data.itemGrantTimer = data.itemGrantTimer + 1

        if data.itemGrantTimer >= battleItems.delayDuration and data.itemGrantID > 0 and onlinePlayPlayers.ownsPlayer(p) then
            data.itemGrantState = battleItems.GRANT_STATE.PREVIEW
            data.itemGrantTimer = 0

            if onlinePlayPlayers.canMakeSound(p) then
                SFX.play(battleItems.previewSound)
            end

            if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
                itemPreviewCommand:send(0, data.itemGrantID,data.itemGrantIsFromReserve)
            end
        end
    elseif data.itemGrantState == battleItems.GRANT_STATE.PREVIEW then
        data.itemGrantTimer = data.itemGrantTimer + 1

        if data.itemGrantTimer >= battleItems.previewDuration and onlinePlayPlayers.ownsPlayer(p) then
            spawnItem(p)

            data.itemGrantState = battleItems.GRANT_STATE.INACTIVE
            data.itemGrantTimer = 0
            data.itemGrantID = 0

            if data.itemGrantIsFromCoins then
                data.itemGrantIsFromCoins = false
                data.coins = 0
            end

            if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
                itemFinishedCommand:send(0)
            end
        end
    end
end

local function drawPreviewItem(p,cam)
    local data = battlePlayer.getPlayerData(p)

    if data.itemGrantState ~= battleItems.GRANT_STATE.PREVIEW or data.itemGrantID <= 0 then
        return
    end

    local texture = Graphics.sprites.npc[data.itemGrantID].img
    if texture == nil then
        return
    end

    local x,y = getItemSpawnPosition(p,data.itemGrantID)

    local scale = 1 + math.sin(data.itemGrantTimer*math.pi/8)*0.1

    local config = NPC.config[data.itemGrantID]
    local gfxwidth = config.gfxwidth
    local gfxheight = config.gfxheight

    if gfxwidth == 0 and gfxheight == 0 then
        gfxwidth = config.width
        gfxheight = config.height
    end

    x = x + config.gfxoffsetx
    y = y + config.gfxoffsety + (config.height - gfxheight)*0.5

    if battleCamera.cameraIsFocusedOnPlayer(cam.idx,p.idx) then
        y = math.max(y,cam.y + gfxheight*0.5 + 8)
    end

    Graphics.drawBox{
        texture = texture,priority = -4,
        centred = true,sceneCoords = true,
        color = Color.white.. 0.8,

        width = gfxwidth*scale,height = gfxheight*scale,
        sourceWidth = gfxwidth,sourceHeight = gfxheight,
        x = x,y = y,
    }
end


function battleItems.onTick()
    local coinsForItem = battleItems.getCoinsForItem()

    for _,p in ipairs(Player.get()) do
        local data = battlePlayer.getPlayerData(p)

        if onlinePlayPlayers.ownsPlayer(p) and data.isActive and not data.isDead and data.itemGrantState == battleItems.GRANT_STATE.INACTIVE then
            if p.keys.dropItem == KEYS_PRESSED and battleItems.playerHasReserveBox(p) and p.reservePowerup > 0 then
                battleItems.dropReserveItem(p,p.reservePowerup)
                p.reservePowerup = 0
            elseif coinsForItem > 0 and data.coins >= coinsForItem then
                data.itemGrantIsFromCoins = true
                battleItems.grantItem(p)
            end
        end
    end
end

function battleItems.onTickEnd()
    for _,p in ipairs(Player.get()) do
        handleItemGranting(p)
    end

    -- Decrease cooldowns
    for _,npcID in ipairs(battleItems.itemIDList) do
        if battleItems.itemCooldowns[npcID] > 0 then
            battleItems.itemCooldowns[npcID] = battleItems.itemCooldowns[npcID] - 1
            --Text.print(npcID,32,32)
        end
    end
end

function battleItems.onCameraDraw(camIdx)
    local cam = Camera(camIdx)

    for _,p in ipairs(Player.get()) do
        drawPreviewItem(p,cam)

        -- Debug: placement
        local text = battleItems.getPlayerPlacement(p)

        --Text.print(tostring(text),p.x + p.width*0.5 - 8 - cam.x,p.y - 32 - cam.y)
        --Text.print(tostring(p.idx),p.x + p.width*0.5 - 8 - cam.x,p.y - 50 - cam.y)
    end
end


function battleItems.onInitAPI()
    battleGeneral = require("scripts/battleGeneral")
    battlePlayer = require("scripts/battlePlayer")
    battleStars = require("scripts/battleStars")
    battleOptions = require("scripts/battleOptions")
    battleCamera = require("scripts/battleCamera")

    onlinePlay = require("scripts/onlinePlay")
    onlinePlayNPC = require("scripts/onlinePlay_npc")
    onlinePlayPlayers = require("scripts/onlinePlay_players")


    registerEvent(battleItems,"onPostNPCCollect")
    registerEvent(battleItems,"onPostBlockHit")
    registerEvent(battleItems,"onTick")
    registerEvent(battleItems,"onTickEnd")
    registerEvent(battleItems,"onCameraDraw")


    battleItems.initPlacementFunctions()
    battleItems.registerDefaultItems()


    randomItemRequestCommand = onlinePlay.createCommand("battle_items_randomItemRequest",onlinePlay.IMPORTANCE_MAJOR)
    randomItemResponseCommand = onlinePlay.createCommand("battle_items_randomItemResponse",onlinePlay.IMPORTANCE_MAJOR)
    itemPreviewCommand = onlinePlay.createCommand("battle_items_preview",onlinePlay.IMPORTANCE_MAJOR)
    itemFinishedCommand = onlinePlay.createCommand("battle_items_finished",onlinePlay.IMPORTANCE_MAJOR)


    function randomItemRequestCommand.onReceive(sourcePlayerIdx)
        if onlinePlay.currentMode ~= onlinePlay.MODE_HOST then
            return
        end

        local p = Player(sourcePlayerIdx)
        local npcID = battleItems.decideRandomItem(p)

        randomItemResponseCommand:send(sourcePlayerIdx, npcID)
    end

    function randomItemResponseCommand.onReceive(sourcePlayerIdx, npcID)
        if onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT or sourcePlayerIdx ~= onlinePlay.hostPlayerIdx then
            return
        end

        local p = Player(onlinePlay.playerIdx)
        local data = battlePlayer.getPlayerData(p)

        if data.itemGrantState ~= battleItems.GRANT_STATE.DELAY or data.itemGrantID > 0 then
            return
        end

        data.itemGrantID = npcID
    end


    function itemPreviewCommand.onReceive(sourcePlayerIdx, npcID,isFromReserve)
        local p = Player(sourcePlayerIdx)
        local data = battlePlayer.getPlayerData(p)

        data.itemGrantState = battleItems.GRANT_STATE.PREVIEW
        data.itemGrantTimer = 0
        data.itemGrantID = npcID
        data.itemGrantIsFromReserve = isFromReserve

        if onlinePlayPlayers.canMakeSound(p) then
            SFX.play(battleItems.previewSound)
        end
    end

    function itemFinishedCommand.onReceive(sourcePlayerIdx)
        local p = Player(sourcePlayerIdx)
        local data = battlePlayer.getPlayerData(p)

        data.itemGrantState = battleItems.GRANT_STATE.INACTIVE
        data.itemGrantTimer = 0
        data.itemGrantID = 0
        data.itemGrantIsFromCoins = false
    end
end


return battleItems