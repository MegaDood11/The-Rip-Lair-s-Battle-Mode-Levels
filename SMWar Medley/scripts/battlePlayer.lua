local blockutils = require("blocks/blockutils")
local playerManager = require("playerManager")
local textFiles = require("scripts/textFiles")
local textplus = require("textplus")
local easing = require("ext/easing")

local clearpipe = require("blocks/ai/clearpipe")
local starman = require("npcs/ai/starman")
local playerstun = require("playerstun")

local perPlayerCostumes = require("scripts/perPlayerCostumes")

local battleGeneral,battleCamera,battleMessages,battleStars,battleItems
local onlinePlay,onlinePlayNPC,onlinePlayPlayers,onlineChat
local booMushroom

local battlePlayer = {}


local BATTLE_MODE_ADDR = 0x00B2D740
local BATTLE_LIVES_ADDR = mem(0x00B2D754,FIELD_DWORD)
local PLAYER_START_POINT_ADDR = mem(0x00B25148,FIELD_DWORD)
local PLAYERS_COUNT_ADDR = 0x00B2595E


local playerDeathCommand
local playerHarmCommand
local playerStompCommand
local playerPushCommand
local playerForfeitCommand
local setTeamsCommand

local invisiblePlayerStates = table.map{FORCEDSTATE_INVISIBLE,FORCEDSTATE_POWERUP_LEAF,FORCEDSTATE_SWALLOWED}
local dontDisplayNameStates = table.map{FORCEDSTATE_PIPE,FORCEDSTATE_DOOR}

local mutedLinkHitSound = false

local playerBuffer = Graphics.CaptureBuffer(200,200)
local playerOutlineShader
local gradientOutlineShader

local customKillPlayer


local resetPlayerValues = {
    {0x00,FIELD_BOOL,false},
    {0x02,FIELD_BOOL,false},
    {0x04,FIELD_BOOL,false},
    {0x06,FIELD_WORD,0},
    {0x08,FIELD_WORD,0},
    {0x0A,FIELD_BOOL,false},
    {0x0C,FIELD_BOOL,false},
    {0x0E,FIELD_WORD,0},
    {0x10,FIELD_WORD,0},
    {0x12,FIELD_BOOL,false},
    {0x14,FIELD_WORD,0},
    {0x16,FIELD_WORD,1}, -- hearts
    {0x18,FIELD_BOOL,false},
    {0x1A,FIELD_BOOL,false},
    {0x1C,FIELD_WORD,0},
    {0x20,FIELD_FLOAT,0},
    {0x24,FIELD_WORD,0},

    {0x26,FIELD_WORD,0},
    {0x28,FIELD_FLOAT,0},
    {0x2C,FIELD_DFLOAT,0},
    {0x34,FIELD_WORD,0},
    {0x36,FIELD_BOOL,false},
    {0x38,FIELD_WORD,0},
    {0x3A,FIELD_WORD,0},
    {0x3C,FIELD_BOOL,false},
    {0x3E,FIELD_BOOL,false},
    {0x40,FIELD_WORD,0},
    {0x42,FIELD_WORD,0},
    {0x44,FIELD_BOOL,false},
    {0x46,FIELD_WORD,0},
    {0x48,FIELD_WORD,0},

    {0x4A,FIELD_BOOL,false},
    {0x4C,FIELD_WORD,0},
    {0x4E,FIELD_WORD,0},

    {0x50,FIELD_BOOL,false},
    {0x52,FIELD_WORD,0},
    {0x54,FIELD_WORD,0},

    {0x56,FIELD_WORD,0},
    {0x58,FIELD_WORD,0},
    {0x5A,FIELD_WORD,0},
    {0x5C,FIELD_BOOL,false},
    {0x5E,FIELD_BOOL,false},
    {0x60,FIELD_BOOL,false},
    {0x62,FIELD_WORD,0},

    {0x64,FIELD_BOOL,false},
    {0x66,FIELD_BOOL,false},
    {0x68,FIELD_BOOL,false},

    {0x6A,FIELD_WORD,0},
    {0x6C,FIELD_WORD,0},
    {0x6E,FIELD_WORD,0},
    {0x70,FIELD_WORD,0},
    {0x72,FIELD_WORD,0},
    {0x74,FIELD_WORD,0},
    {0x76,FIELD_WORD,0},
    {0x78,FIELD_WORD,0},
    {0x7A,FIELD_WORD,0},
    {0x7C,FIELD_WORD,0},
    {0xB0,FIELD_FLOAT,0},
    {0xB4,FIELD_FLOAT,0},
    {0xB6,FIELD_BOOL,false},
    {0xB8,FIELD_WORD,0},
    {0xBA,FIELD_WORD,0},
    {0xBC,FIELD_WORD,0},

    {"speedX",0},
    {"speedY",0},

    {"mount",0},
    {"mountColor",0},

    {0x10C,FIELD_WORD,0},
    {0x10E,FIELD_WORD,0},
    {0x110,FIELD_WORD,0},

    {"powerup",PLAYER_SMALL},
    {"frame",1},
    {0x118,FIELD_FLOAT,0},
    {0x11C,FIELD_WORD,0},
    {0x11E,FIELD_BOOL,false},
    {0x120,FIELD_BOOL,false},
    {"forcedState",FORCEDSTATE_NONE},
    {"forcedTimer",0},
    {0x12E,FIELD_BOOL,false},
    {0x132,FIELD_BOOL,false},
    {0x134,FIELD_BOOL,false},
    {0x136,FIELD_BOOL,false},
    {0x138,FIELD_FLOAT,0},
    {0x13C,FIELD_BOOL,false},
    {"deathTimer",0},
    {0x140,FIELD_WORD,0},
    {0x142,FIELD_BOOL,false},
    {0x144,FIELD_BOOL,false},

    {0x146,FIELD_WORD,0},
    {0x148,FIELD_WORD,0},
    {0x14A,FIELD_WORD,0},
    {0x14C,FIELD_WORD,0},
    {0x14E,FIELD_WORD,0},

    {0x154,FIELD_WORD,0},
    {0x156,FIELD_BOOL,false},
    {"reservePowerup",0},

    {0x15C,FIELD_WORD,0},
    {0x15E,FIELD_WORD,0},

    {0x160,FIELD_WORD,0},
    {0x162,FIELD_WORD,0},
    {0x164,FIELD_WORD,0},

    {0x168,FIELD_FLOAT,0},
    {0x16C,FIELD_BOOL,false},
    {0x16E,FIELD_BOOL,false},
    {0x170,FIELD_WORD,0},
    {0x172,FIELD_BOOL,false},

    {0x176,FIELD_WORD,0},
    {0x178,FIELD_WORD,0},
}


battlePlayer.HARM_TYPE = {
    NORMAL = 1,
    SMALL_DAMAGE = 2,
    FREEZE = 3,
}


battlePlayer.outlineThickness = 2

battlePlayer.playerDeathEffects = {3,5,129,130,134}
battlePlayer.bootEffects = {26,101,102}

battlePlayer.defenderFavouredProjectileMap = table.map{13,265,171,266,108,292}

battlePlayer.characterBlocksMap = {[622] = CHARACTER_MARIO,[623] = CHARACTER_LUIGI,[624] = CHARACTER_PEACH,[625] = CHARACTER_TOAD,[631] = CHARACTER_LINK}
battlePlayer.characterBlocksList = table.unmap(battlePlayer.characterBlocksMap)

battlePlayer.defaultCharacters = {CHARACTER_MARIO,CHARACTER_LUIGI,CHARACTER_TOAD,CHARACTER_PEACH}

battlePlayer.characterNames = {"Mario","Luigi","Peach","Toad","Link"}

battlePlayer.keyConfigList = {"jump","run","altJump","altRun","up","down","left","right","pause","dropItem"}
battlePlayer.keyConfigNames = {jump = "Jump",run = "Run",altJump = "Spin Jump",altRun = "Tanooki Statue",up = "Up",down = "Down",left = "Left",right = "Right",pause = "Pause",dropItem = "Select"}

battlePlayer.nameTextFormat = {
    font = textplus.loadFont("resources/font/outlinedFont.ini"),
    xscale = 1,yscale = 1,plaintext = true,
}

battlePlayer.maxHearts = 2



battlePlayer.startPoints = {}


battlePlayer.startPointNPCID = 0


local playerColorGradients = {
    ["gay"] = {Color.fromHexRGB(0xFE0000),Color.fromHexRGB(0xFF8E01),Color.fromHexRGB(0xFFED00),Color.fromHexRGB(0x018114),Color.fromHexRGB(0x014CFF),Color.fromHexRGB(0x8A018C)},
    ["trans"] = {Color.fromHexRGB(0x5BCEFA),Color.fromHexRGB(0xF5A9B8),Color.white,Color.fromHexRGB(0xF5A9B8)},
    ["transgender"] = {Color.fromHexRGB(0x5BCEFA),Color.fromHexRGB(0xF5A9B8),Color.white,Color.fromHexRGB(0xF5A9B8)},
    ["nonbinary"] = {Color.fromHexRGB(0xFFF433),Color.white,Color.fromHexRGB(0x9B59D0),Color.fromHexRGB(0x2D2D2D)},
    ["non-binary"] = {Color.fromHexRGB(0xFFF433),Color.white,Color.fromHexRGB(0x9B59D0),Color.fromHexRGB(0x2D2D2D)},
    ["enby"] = {Color.fromHexRGB(0xFFF433),Color.white,Color.fromHexRGB(0x9B59D0),Color.fromHexRGB(0x2D2D2D)},
    ["ie"] = {Color.fromHexRGB(0x009A49),Color.white,Color.fromHexRGB(0xFF7901)},
    ["irish"] = {Color.fromHexRGB(0x009A49),Color.white,Color.fromHexRGB(0xFF7901)},
    ["ireland"] = {Color.fromHexRGB(0x009A49),Color.white,Color.fromHexRGB(0xFF7901)},
    ["bi"] = {Color.fromHexRGB(0xD60270),Color.fromHexRGB(0xD60270),Color.fromHexRGB(0x9B4F96),Color.fromHexRGB(0x0038A8),Color.fromHexRGB(0x0038A8)},
    ["bisexual"] = {Color.fromHexRGB(0xD60270),Color.fromHexRGB(0xD60270),Color.fromHexRGB(0x9B4F96),Color.fromHexRGB(0x0038A8),Color.fromHexRGB(0x0038A8)},
    ["pan"] = {Color.fromHexRGB(0xFF228C),Color.fromHexRGB(0xFFD800),Color.fromHexRGB(0x22B1FF)},
    ["pansexual"] = {Color.fromHexRGB(0xFF228C),Color.fromHexRGB(0xFFD800),Color.fromHexRGB(0x22B1FF)},
    ["mlm"] = {Color.fromHexRGB(0x078D70),Color.fromHexRGB(0x99E8C2),Color.white,Color.fromHexRGB(0x7BADE3),Color.fromHexRGB(0x3E1A78)},
    ["yaoi"] = {Color.fromHexRGB(0x078D70),Color.fromHexRGB(0x99E8C2),Color.white,Color.fromHexRGB(0x7BADE3),Color.fromHexRGB(0x3E1A78)},
    ["sonadow"] = {Color.fromHexRGB(0x078D70),Color.fromHexRGB(0x99E8C2),Color.white,Color.fromHexRGB(0x7BADE3),Color.fromHexRGB(0x3E1A78)},
    ["lesbian"] = {Color.fromHexRGB(0xD52D00),Color.fromHexRGB(0xFF9A56),Color.white,Color.fromHexRGB(0xD362A4),Color.fromHexRGB(0xA30262)},
    ["yuri"] = {Color.fromHexRGB(0xD52D00),Color.fromHexRGB(0xFF9A56),Color.white,Color.fromHexRGB(0xD362A4),Color.fromHexRGB(0xA30262)},
    ["aro"] = {Color.fromHexRGB(0x3DA542),Color.fromHexRGB(0xA7D379),Color.white,Color.fromHexRGB(0xA9A9A9),Color.fromHexRGB(0x383858)},
    ["aromantic"] = {Color.fromHexRGB(0x3DA542),Color.fromHexRGB(0xA7D379),Color.white,Color.fromHexRGB(0xA9A9A9),Color.fromHexRGB(0x383858)},
    ["ace"] = {Color.fromHexRGB(0x383858),Color.fromHexRGB(0x808080),Color.white,Color.fromHexRGB(0x800080)},
    ["asexual"] = {Color.fromHexRGB(0x383858),Color.fromHexRGB(0x808080),Color.white,Color.fromHexRGB(0x800080)},
}
local maxGradientColors = 6


local initialiseCustomRawKeys

do
    local keysList = {"up","down","left","right","jump","altJump","run","altRun","dropItem","pause"}

    local nextKeyMap = {}
    for i,name in ipairs(keysList) do
        nextKeyMap[name] = keysList[i + 1]
    end
    nextKeyMap[""] = keysList[1]

    local function iterateKeys(tbl, key)
		local newKey = keysNextMap[key]

		if newKey ~= nil then
			return newKey,tbl[newKey]
		end
	end


    local customRawKeysMT = {
        __index = function(tbl,key)
            local last = tbl._last[key]
            local now = tbl._now[key]

            if last == nil or now == nil then
                return nil
            end

            if now then
                if last then
                    return KEYS_DOWN
                else
                    return KEYS_PRESSED
                end
            else
                if last then
                    return KEYS_RELEASED
                else
                    return KEYS_UP
                end
            end
        end,
        __newindex = function(tbl,key,value)
            
        end,

        __pairs = function(tbl)
            return iterateKeys,tbl,""
        end,
    }


    function initialiseCustomRawKeys()
        local keys = {_last = {},_now = {}}

        for _,name in ipairs(keysList) do
            keys._last[name] = false
            keys._now[name] = false
        end
        
        setmetatable(keys,customRawKeysMT)

        return keys
    end
end



local function resetPlayerData(p,data)
    if data.itemGrantIsFromCoins then
        data.coins = 0
    end

    data.itemGrantState = battleItems.GRANT_STATE.INACTIVE
    data.itemGrantTimer = 0
    data.itemGrantIsFromCoins = false
    data.itemGrantIsFromReserve = false
    data.itemGrantID = 0

    data.respawnTimer = 0
    data.deathTimer = 0
    data.deathStart = vector(0,0)
    data.deathStartSection = 0

    data.lostStarsAmount = 0

    data.nameOpacity = 0

    data.shakeOffset = 0

    data.isActive = true
end

function battlePlayer.getPlayerData(p)
    local data = p.data._battle

    if data == nil then
        data = {}
        p.data._battle = data

        data.rawKeys = initialiseCustomRawKeys()
        data.onlineKeys = {}


        data.noplayerinteraction = false

        data.allowedToHarm = false
        data.dontSendHarmCommand = false

        data.forfeited = false

        data.seamlessWrapOffsetX = 0
        data.seamlessWrapOffsetY = 0


        data.respawnDuration = 0

        data.lives = -1
        data.stars = 0
        data.coins = 0
        data.points = 0
        

        resetPlayerData(p,data)
    end

    return data
end


function battlePlayer.teamsAreEnabled()
    return (onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and battleGeneral.gameData.teamsEnabled)
end

function battlePlayer.getTeam(index)
    if not battlePlayer.teamsAreEnabled() then
        return 0
    end

    if battleGeneral.isInHub then
        return battleGeneral.gameData.playerTeams[index] or 0
    else
        return battleGeneral.gameData.decidedPlayerTeams[index] or 0
    end
end

function battlePlayer.playersAreOnSameTeam(indexA,indexB)
    if battlePlayer.teamsAreEnabled() then
        local teamA = battlePlayer.getTeam(indexA)
        local teamB = battlePlayer.getTeam(indexB)

        return (teamA == teamB and teamA > 0)
    else
        return false
    end
end


function battlePlayer.getName(index)
    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        local data = onlinePlay.getUserData(index)

        if data ~= nil and data.username ~= nil and data.username ~= "" then
            return data.username
        end
    end

    return "P".. index
end

function battlePlayer.getColor(index)
    if battlePlayer.teamsAreEnabled() then
        return battleGeneral.teamColors[battlePlayer.getTeam(index)]
    end

    local colorIdx = index

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        local data = onlinePlay.getUserData(index)

        if data ~= nil then
            colorIdx = data.colorIdx
        end
    end

    return battleGeneral.playerColors[colorIdx] or Color.white
end

function battlePlayer.getColorGradient(index)
    if battlePlayer.teamsAreEnabled() then
        return nil
    end

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        local data = onlinePlay.getUserData(index)

        if data ~= nil then
            return playerColorGradients[data.username]
        end
    end

    return nil
end


local characterHeadImages = {}

function battlePlayer.getPlayerHead(p)
    local character,costume

    if type(p) ~= "Player" then -- outdated; using character ID instead of a player object
        character = p
        costume = nil
    else
        character = p.character
        costume = p:getCostume()
    end

    local key = costume or character

    if characterHeadImages[key] == nil then
        if costume ~= nil then
            -- Use costume image, if available
            local path = Misc.resolveGraphicsFile("resources/characterHeads/".. costume.. ".png")

            if path ~= nil then
                characterHeadImages[key] = Graphics.loadImage(path)
                return characterHeadImages[key]
            end
        end

        -- Use character image
        local path = Misc.resolveGraphicsFile("resources/characterHeads/".. playerManager.getName(character).. ".png")

        if path ~= nil then
            characterHeadImages[key] = Graphics.loadImage(path)
            return characterHeadImages[key]
        end

        -- Otherwise, just use a blank image
        characterHeadImages[key] = Graphics.loadImageResolved("stock-0.png")
    end

    return characterHeadImages[key]
end


function battlePlayer.getPlayerIsActive(p)
    local data = battlePlayer.getPlayerData(p)

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        if not onlinePlay.isConnected(p.idx) then
            return false
        end
    end
    
    return data.isActive
end

function battlePlayer.getActivePlayers()
    local tbl = {}

    for _,p in ipairs(Player.get()) do
        if battlePlayer.getPlayerIsActive(p) then
            table.insert(tbl,p)
        end
    end

    return tbl
end

function battlePlayer.getActivePlayerCount()
    local count = 0

    for _,p in ipairs(Player.get()) do
        if battlePlayer.getPlayerIsActive(p) then
            count = count + 1
        end
    end

    return count
end

function battlePlayer.setPlayerIsActive(p,newIsActive)
    local data = battlePlayer.getPlayerData(p)

    if newIsActive and not data.isActive then
        battlePlayer.reset(p,true)
        data.isActive = true
    elseif not newIsActive and data.isActive then
        battlePlayer.reset(p,true)
        data.isActive = false

        p.forcedState = FORCEDSTATE_SWALLOWED
        p.forcedTimer = p.idx
        p:mem(0xBA,FIELD_WORD,p.idx)
    end
end


function battlePlayer.sendTeamsUpdate()
    if onlinePlay.currentMode ~= onlinePlay.MODE_HOST then
        return
    end

    if battleGeneral.gameData.teamsEnabled then
        setTeamsCommand:send(0, battleGeneral.gameData.playerTeams)
    else
        setTeamsCommand:send(0, nil)
    end
end


function battlePlayer.getStartPoint(idx)
    local startPoint = battlePlayer.startPoints[idx]

    if startPoint == nil then
        startPoint = battlePlayer.startPoints[1]
        assert(startPoint ~= nil,"No start point defined for player ".. idx.. ".")

        startPoint = startPoint - vector((idx - 1)*32,0)
    end

    return startPoint
end

function battlePlayer.reset(p,goToStart)
    for _,a in ipairs(resetPlayerValues) do
        if type(a[1]) == "string" then
            p[a[1]] = a[2]
        else
            p:mem(a[1],a[2],a[3])
        end
    end

    local settings = p:getCurrentPlayerSetting()

    p.width = settings.hitboxWidth
    p.height = settings.hitboxHeight

    if goToStart then
        local startPoint = battlePlayer.getStartPoint(p.idx)

        p.x = startPoint.x - p.width*0.5
        p.y = startPoint.y - p.height

        p.section = Section.getIdxFromCoords(p)

        local b = p.sectionObj.boundary

        if (p.x + p.width*0.5) > (b.right + b.left)*0.5 then
            p.direction = DIR_LEFT
        else
            p.direction = DIR_RIGHT
        end
    end

    local data = battlePlayer.getPlayerData(p)

    resetPlayerData(p,data)
    
    starman.stop(p)
end


function battlePlayer.saveCharacters(treatAsOnline)
    if treatAsOnline == nil then
        treatAsOnline = (onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE)
    end

    for _,p in ipairs(Player.get()) do
        local costumes = perPlayerCostumes.getAllCostumes(p.idx)

        if not treatAsOnline then
            battleGeneral.saveData.playerCharacters[p.idx] = p.character
            battleGeneral.saveData.playerCostumes[p.idx] = costumes
        elseif p.idx == onlinePlay.playerIdx then
            battleGeneral.saveData.playerCharacters[1] = p.character
            battleGeneral.saveData.playerCostumes[1] = costumes
        end

        battleGeneral.gameData.playerCharacters[p.idx] = p.character
        battleGeneral.gameData.playerCostumes[p.idx] = costumes
    end
end

function battlePlayer.loadCharacters(treatAsOnline)
    if treatAsOnline == nil then
        treatAsOnline = (onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE)
    end

    for _,p in ipairs(Player.get()) do
        local savedCharacter

        if treatAsOnline then
            -- Load from game data
            savedCharacter = battleGeneral.gameData.playerCharacters[p.idx]
        else
            -- Load from save data
            savedCharacter = battleGeneral.saveData.playerCharacters[p.idx]
        end

        if savedCharacter == nil or savedCharacter < 1 or savedCharacter > 5 then
            p.character = battlePlayer.defaultCharacters[p.idx] or CHARACTER_MARIO
        else
            p.character = savedCharacter
        end
    end
end

function battlePlayer.loadCostumes(treatAsOnline)
    if treatAsOnline == nil then
        treatAsOnline = (onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE)
    end

    for _,p in ipairs(Player.get()) do
        local savedCostumes

        if treatAsOnline then
            -- Load from game data
            if p.idx == onlinePlay.playerIdx or onlinePlay.isConnected(p.idx) then
                savedCostumes = battleGeneral.gameData.playerCostumes[p.idx]
            end
        else
            -- Load from save data
            if p.idx <= battleGeneral.gameData.playerCount then
                savedCostumes = battleGeneral.saveData.playerCostumes[p.idx]
            end
        end

        perPlayerCostumes.setAllCostumes(p.idx,savedCostumes or {})
    end
end


function battlePlayer.setPlayerCount(count,resetEveryone)
    local startIdx = Player.count() + 1
    if resetEveryone then
        startIdx = 1
    end

    mem(PLAYERS_COUNT_ADDR,FIELD_WORD,count)

    for i = startIdx,count do
        local p = Player(i)

        local savedCharacter
        if onlinePlay.currentMode == onlinePlay.MODE_OFFLINE then
            savedCharacter = battleGeneral.saveData.playerCharacters[p.idx]
        else
            savedCharacter = battleGeneral.gameData.playerCharacters[p.idx]
        end

        if savedCharacter == nil or savedCharacter < 1 or savedCharacter > 5 then
            p.character = battlePlayer.defaultCharacters[p.idx] or CHARACTER_MARIO
        else
            p.character = savedCharacter
        end

        battlePlayer.reset(p,true)
    end
end


local function findPlayerStartPoints()
    -- Use ordinary start points.
    for i = 1,2 do
        local addr = PLAYER_START_POINT_ADDR + (i - 1)*48
        local x      = mem(addr       ,FIELD_DFLOAT)
        local y      = mem(addr + 0x08,FIELD_DFLOAT)
        local height = mem(addr + 0x10,FIELD_DFLOAT)
        local width  = mem(addr + 0x18,FIELD_DFLOAT)

        if x ~= 0 or y ~= 0 then
            battlePlayer.startPoints[i] = vector(x + width*0.5,y + height)
        else
            battlePlayer.startPoints[i] = nil            
        end
    end

    -- Use NPC's to find start points.
    if battlePlayer.startPointNPCID > 0 then
        for _,n in NPC.iterate(battlePlayer.startPointNPCID) do
            -- Assign position to player start point
            local index = n.data._settings.index

            if index > 0 and index <= math.max(battleGeneral.maxLocalPlayers,battleGeneral.maxOnlinePlayers) then
                assert(battlePlayer.startPoints[index] == nil,"Multiple start points placed for player ".. index.. ".")
                battlePlayer.startPoints[index] = vector(n.x + n.width*0.5,n.y + n.height)
            end

            -- Delete
            local onlineData = onlinePlayNPC.getData(n)

            onlineData.allowedToDie = true

            n.spawnId = 0
            n:kill(HARM_TYPE_VANISH)
        end
    end
end

local function findWinningPlayer()
    if battleGeneral.isInHub then
        return nil
    end

    if battleGeneral.gameData.playerCount <= 1 then
        local data = battlePlayer.getPlayerData(Player(1))

        if data.isActive then
            return nil
        else
            return 0
        end
    end

    -- Teams
    if battlePlayer.teamsAreEnabled() then
        local allDead = {true,true}

        for _,p in ipairs(Player.get()) do
            local data = battlePlayer.getPlayerData(p)
            local teamIdx = battlePlayer.getTeam(p.idx)

            if data.isActive and teamIdx > 0 then
                allDead[teamIdx] = false
            end
        end

        if allDead[1] and allDead[2] then
            return 0
        end

        if allDead[1] then
            return 2
        elseif allDead[2] then
            return 1
        end

        return nil
    end

    -- Free-for-all
    local allDead = true
    local candidateIdx

    for _,p in ipairs(Player.get()) do
        local data = battlePlayer.getPlayerData(p)

        if data.isActive then
            if candidateIdx ~= nil then
                return
            end

            candidateIdx = p.idx
            allDead = false
        end
    end

    if allDead then
        return 0
    end

    return candidateIdx
end


local function applyStartingMushroom()
    if battleGeneral.isInHub then
        return
    end

    local fullRuleset = battleOptions.getFullRuleset()

    if not fullRuleset.general.startWithMushroom then
        return
    end

    for _,p in ipairs(Player.get()) do
        p.powerup = PLAYER_BIG
        p:mem(0x16,FIELD_WORD,2)
    end
end


function battlePlayer.onStart()
    -- Setup player start points
    findPlayerStartPoints()

    -- Setup players
    if battleGeneral.isInHub then
        battlePlayer.setPlayerCount(battleGeneral.maxOnlinePlayers,true)
    else
        battlePlayer.setPlayerCount(math.max(battleGeneral.gameData.playerCount,2),true)
    end

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE or GameData.onlinePlay.mode ~= onlinePlay.MODE_OFFLINE then
        for playerIdx = 1,Player.count() do
            if not onlinePlay.isConnected(playerIdx) then
                battlePlayer.setPlayerIsActive(Player(playerIdx),false)
            end
        end
    else
        for playerIdx = (battleGeneral.gameData.playerCount + 1),Player.count() do
            battlePlayer.setPlayerIsActive(Player(playerIdx),false)
        end
    end

    -- If the option is enabled, apply big powerup state to players
    applyStartingMushroom()

    -- Set battle mode flag. This, for example, allows Link's sword to attack other players
    mem(BATTLE_MODE_ADDR,FIELD_BOOL,true)

    -- Set battle lives to 0; death is now handled by custom code (see onPlayerKill)
    for i = 1,200 do
        mem(BATTLE_LIVES_ADDR + (i - 1)*2,FIELD_WORD,0)
    end
end

function battlePlayer.onStartLate()
    -- Set lives
    for _,p in ipairs(Player.get()) do
        local data = battlePlayer.getPlayerData(p)

        local modeRuleset = battleOptions.getModeRuleset()

        if modeRuleset.lives ~= nil and modeRuleset.lives > 0 then
            data.lives = modeRuleset.lives
        else
            data.lives = -1
        end
    end

    battlePlayer.loadCharacters()
    battlePlayer.loadCostumes()
end


function battlePlayer.onExitLevel(winType)
    -- Reset battle mode flag
    mem(BATTLE_MODE_ADDR,FIELD_BOOL,false)

    -- Save player characters
    if battleGeneral.isInHub then
        battlePlayer.saveCharacters()
    end

    -- Reset player count, fixes some dumb bugs
    battlePlayer.setPlayerCount(1,false)

    -- Decide automatic teams
    if onlinePlay.currentMode == onlinePlay.MODE_HOST and battlePlayer.teamsAreEnabled() then
        battleGeneral.gameData.decidedPlayerTeams = {}

        -- Count and assign players who are already on a specific team
        local teamMemberCounts = {0,0}
        local autoTeamPlayerIndices = {}

        for _,user in ipairs(onlinePlay.getUsers()) do
            local teamIdx = battleGeneral.gameData.playerTeams[user.playerIdx] or 0

            if teamIdx > 0 then
                battleGeneral.gameData.decidedPlayerTeams[user.playerIdx] = teamIdx
                teamMemberCounts[teamIdx] = teamMemberCounts[teamIdx] + 1
            else
                table.insert(autoTeamPlayerIndices,user.playerIdx)
            end
        end

        -- Distribute the auto-team players into their teams
        table.ishuffle(autoTeamPlayerIndices)

        for _,playerIdx in ipairs(autoTeamPlayerIndices) do
            local chosenTeamIdx

            if teamMemberCounts[1] > teamMemberCounts[2] then
                chosenTeamIdx = 2
            elseif teamMemberCounts[1] < teamMemberCounts[2] then
                chosenTeamIdx = 1
            else
                chosenTeamIdx = RNG.randomInt(1,2)
            end

            battleGeneral.gameData.decidedPlayerTeams[playerIdx] = chosenTeamIdx
            teamMemberCounts[chosenTeamIdx] = teamMemberCounts[chosenTeamIdx] + 1
        end
    end
end


local function setPlayerKeys(p)
    local data = battlePlayer.getPlayerData(p)

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        --local keys = p.rawKeys
        local keys = Player(1).rawKeys

        for name,_ in pairs(p.keys) do
            local value
            if p.idx == onlinePlay.playerIdx then
                if onlineChat.active then
                    value = false
                else
                    value = keys[name]
                end
            else
                value = data.onlineKeys[name]
            end

            p.keys[name] = value

            data.rawKeys._last[name] = data.rawKeys._now[name]
            data.rawKeys._now[name] = (not not value)
        end
    elseif p.idx > 1 and Player.count() > 2 then
        local config
        if p.idx == 2 then
            if Misc.GetSelectedControllerName(2) == "Keyboard" then
                config = inputConfig2
            end
        end

        for k,v in pairs(p.keys) do
            if config ~= nil then
                p.keys[k] = Misc.GetKeyState(config[k:lower()])
            else
                p.keys[k] = false
            end
        end

        for name,value in pairs(p.keys) do
            data.rawKeys._last[name] = data.rawKeys._now[name]
            data.rawKeys._now[name] = (not not value)
        end
    else
        for name,value in pairs(p.rawKeys) do
            data.rawKeys._last[name] = data.rawKeys._now[name]
            data.rawKeys._now[name] = (not not value)
        end
    end

    -- Overwrite clear pipe inputs
    if clearpipe.overrideInput ~= nil then
        for name,value in pairs(p.keys) do
            clearpipe.overrideInput(p,name,value)
        end
    end

    -- Some restrictions on controls, same as vanilla
    if p.keys.left and p.keys.right then
        p.keys.left = false
        p.keys.right = false
    end
    if p.keys.up and p.keys.down then
        p.keys.up = false
        p.keys.down = false
    end

    if p.keys.altRun and p.powerup ~= PLAYER_TANOOKIE and p.mount == MOUNT_NONE then
        p.keys.run = true
    end
end

function battlePlayer.onInputUpdate()
    for _,p in ipairs(Player.get()) do
        setPlayerKeys(p)
    end
end


local function handlePlayerWarping(p)
    if p.forcedState == FORCEDSTATE_PIPE then
        local warp = Warp(p:mem(0x15E,FIELD_WORD) - 1)
        local settings = p:getCurrentPlayerSetting()
        local holdingNPC = p.holdingNPC

        if p.forcedTimer == 1 then
            -- https://github.com/smbx/smbx-legacy-source/blob/master/modPlayer.bas#L7602
            if warp.noYoshi then
                p:mem(0x12E,FIELD_BOOL,false)
                p:mem(0x10E,FIELD_WORD,0)
                p.mount = MOUNT_NONE
                p.mountColor = 0

                p.width = settings.hitboxWidth
                p.height = settings.hitboxHeight
            end

            if warp.exitDirection == 1 or warp.exitDirection == 3 then
                if warp.exitDirection == 1 then
                    p.y = warp.exitY - p.height - 8
                else
                    p.y = warp.exitY + warp.exitHeight + 8
                end

                p.x = warp.exitX + warp.exitWidth*0.5 - p.width*0.5

                if holdingNPC ~= nil then
                    holdingNPC.x = p.x + p.width*0.5 - holdingNPC.width*0.5
                end
            else
                if p.mount == MOUNT_YOSHI then
                    p:mem(0x12E,FIELD_BOOL,true)
                    p.height = 30
                elseif p.mount == MOUNT_NONE then
                    p.frame = 1
                end

                if warp.exitDirection == 2 then
                    p.x = warp.exitX - p.width*0.5 - 8
                    p.direction = DIR_RIGHT
                else
                    p.x = warp.exitX + warp.exitWidth + 8
                    p.direction = DIR_LEFT
                end

                p.y = warp.exitY + warp.exitHeight - p.height - 2

                if holdingNPC ~= nil then
                    if p.direction == DIR_RIGHT then
                        holdingNPC.x = p.x + settings.grabOffsetX
                    else
                        holdingNPC.x = p.x + p.width - settings.grabOffsetX - holdingNPC.width
                    end
                end
            end

            p.forcedTimer = 100

            p.section = Section.getIdxFromCoords(p)

            if holdingNPC ~= nil then
                holdingNPC.y = p.y + settings.grabOffsetY + 32 - holdingNPC.height
                holdingNPC.section = p.section
            end
        elseif p.forcedTimer == 3 then
            -- https://github.com/smbx/smbx-legacy-source/blob/master/modPlayer.bas#L7814
            local holdingNPC = p.holdingNPC

            p.forcedState = FORCEDSTATE_NONE
            p.forcedTimer = 0

            p.speedX = 0
            p.speedY = 0

            p:mem(0x11E,FIELD_BOOL,false)
            p:mem(0x120,FIELD_BOOL,false)
            p:mem(0x138,FIELD_FLOAT,0)
            p:mem(0x15C,FIELD_WORD,20)

            if holdingNPC ~= nil then
                holdingNPC:mem(0x138,FIELD_WORD,0)
            end
        end
    elseif p.forcedState == FORCEDSTATE_DOOR then
        if p.forcedTimer >= 29 then
            -- https://github.com/smbx/smbx-legacy-source/blob/master/modPlayer.bas#L7867
            local warp = Warp(p:mem(0x15E,FIELD_WORD) - 1)
            local settings = p:getCurrentPlayerSetting()
            
            if warp.noYoshi then
                p:mem(0x10E,FIELD_WORD,0)
                p.mount = MOUNT_NONE
                p.mountColor = 0

                p.width = settings.hitboxWidth
                p.height = settings.hitboxHeight

                p.frame = 1
            end

            p.x = warp.exitX + warp.exitWidth*0.5 - p.width*0.5
            p.y = warp.exitY + warp.exitHeight - p.height
            p.section = Section.getIdxFromCoords(p)

            p.forcedState = FORCEDSTATE_NONE
            p.forcedTimer = 0

            p:mem(0x15C,FIELD_WORD,40)
        end
    end
end


local function canSlideHurt(p)
    return (
        (p:mem(0x3C,FIELD_BOOL) and p:mem(0x3E,FIELD_BOOL)) -- sliding on a slope
        or (p:mem(0x4A,FIELD_BOOL) and math.abs(p.speedX) > 3) -- statue sliding
    )
end

local function canStompHurt(p)
    return (p.isValid and battleGeneral.mode == 0) or (p.mount == MOUNT_BOOT or p:mem(0x4A,FIELD_BOOL) or canSlideHurt(p))
end

local function stompReaction(stompedPlayer,stompingPlayer)
    local stompedData = battlePlayer.getPlayerData(stompedPlayer)

    -- Harm
    if canStompHurt(stompingPlayer) and not battlePlayer.playersAreOnSameTeam(stompedPlayer.idx,stompingPlayer.idx) then
        if onlinePlayPlayers.ownsPlayer(stompedPlayer) then
            stompedPlayer:harm()
        end
    elseif battleGeneral.mode >= 0 and battleGeneral.mode ~= battleGeneral.gameMode.ARENA then
        if not battlePlayer.playersAreOnSameTeam(stompedPlayer.idx,stompingPlayer.idx) then
            -- Invincibility frames
            stompedPlayer:mem(0x140,FIELD_WORD,stompedPlayer:mem(0x140,FIELD_WORD) + 75)

            -- Lose stars
            battleStars.lose(stompedPlayer,1)
        else
            -- Invincibility frames
            stompedPlayer:mem(0x140,FIELD_WORD,stompedPlayer:mem(0x140,FIELD_WORD) + 25)

            -- Trade stars
            battleStars.trade(stompedPlayer,stompingPlayer,1)
        end

        SFX.play(76)
    end

    -- Effect
    if onlinePlayPlayers.canMakeSound(stompedPlayer) or onlinePlayPlayers.canMakeSound(stompingPlayer) then
        SFX.play(2)
    end

    Effect.spawn(75,stompingPlayer.x + stompingPlayer.width*0.5 - 16,stompingPlayer.y + stompingPlayer.height - 16)

    -- Event
    battlePlayer.onPlayerStomped(stompedPlayer,stompingPlayer)

    -- Send a message
    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and stompingPlayer.idx == onlinePlay.playerIdx then
        playerStompCommand:send(0, stompedPlayer.idx)
    end
end


local function hasPlayerInteraction(p)
    if p.forcedState ~= FORCEDSTATE_NONE and p.forcedState ~= FORCEDSTATE_PIPE then
        return false
    end

    if p:mem(0x140,FIELD_WORD) > 0 or p.mount == MOUNT_CLOWNCAR then
        return false
    end

    if booMushroom.isActive(p) and p.mount == MOUNT_NONE and not p:mem(0x0C,FIELD_BOOL) then
        return false
    end

    local data = battlePlayer.getPlayerData(p)

    if data.noplayerinteraction then
        return false
    end

    return true
end

local function canStomp(playerA,playerB) -- A is the attacker here
    if playerA.forcedState ~= FORCEDSTATE_NONE then
        return
    end

    -- Regular stomp
    if (playerA.y + playerA.height - playerA.speedY - 4) <= (playerB.y - playerB.speedY) then
        return true
    end

    -- Just unducked
    if playerB:mem(0x134,FIELD_BOOL) then
        local settings = PlayerSettings.get(playerManager.getBaseID(playerB.character),playerB.powerup)

        if (playerA.y + playerA.height - playerA.speedY - 4) <= (playerB.y + playerB.height - settings.hitboxDuckHeight - playerB.speedY) then
            return true
        end
    end

    return false
end

local function playerToPlayerCollision(playerA,playerB)
    -- Starman
    if not battlePlayer.playersAreOnSameTeam(playerA.idx,playerB.idx) then
        if playerA.hasStarman then
            if onlinePlayPlayers.ownsPlayer(playerB) then
                playerB:harm()
            end

            return
        elseif playerB.hasStarman then
            if onlinePlayPlayers.ownsPlayer(playerA) then
                playerA:harm()
            end

            return
        end
    end


    -- Stomping
    if canStomp(playerA,playerB) then
        playerA:mem(0x11C,FIELD_WORD,Defines.jumpheight)
        playerA.speedY = Defines.jumpspeed
        playerA.y = playerB.y - playerA.height - 0.1

        playerB:mem(0x11C,FIELD_WORD,0)
        playerB:mem(0x11E,FIELD_BOOL,false)
        playerB.speedY = math.max(0.1,playerB.speedY)

        if onlinePlayPlayers.ownsPlayer(playerA) then
            stompReaction(playerB,playerA)
        end

        return
    end

    if canStomp(playerB,playerA) then
        playerB:mem(0x11C,FIELD_WORD,Defines.jumpheight)
        playerB.speedY = Defines.jumpspeed
        playerB.y = playerA.y - playerB.height - 0.1

        playerA:mem(0x11C,FIELD_WORD,0)
        playerA:mem(0x11E,FIELD_BOOL,false)
        playerA.speedY = math.max(0.1,playerA.speedY)

        if onlinePlayPlayers.ownsPlayer(playerB) then
            stompReaction(playerA,playerB)
        end

        return
    end


    if playerA.forcedState ~= FORCEDSTATE_NONE or playerB.forcedState ~= FORCEDSTATE_NONE then
        return false
    end


    if not onlinePlayPlayers.ownsPlayer(playerA) and not onlinePlayPlayers.ownsPlayer(playerB) then
        return
    end


    -- Slide killing
    if not battlePlayer.playersAreOnSameTeam(playerA.idx,playerB.idx) then
        if canSlideHurt(playerA) then
            if onlinePlayPlayers.ownsPlayer(playerB) then
                playerB:harm()
            end

            return
        elseif canSlideHurt(playerB) then
            if onlinePlayPlayers.ownsPlayer(playerA) then
                playerA:harm()
            end

            return
        end

        -- Statue
        if playerA:mem(0x4A,FIELD_BOOL) or playerB:mem(0x4A,FIELD_BOOL) then
            return
        end
    end


    -- Pushing
    if (playerA.x + playerA.width - playerA.speedX) <= (playerB.x - playerB.speedX)
    or (playerA.x - playerA.speedX) >= (playerB.x + playerB.width - playerB.speedX)
    then
        if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
            if onlinePlayPlayers.ownsPlayer(playerA) then
                playerPushCommand:send(0, playerB.idx,playerA.speedX)
            end

            if onlinePlayPlayers.ownsPlayer(playerB) then
                playerPushCommand:send(0, playerA.idx,playerB.speedX)
            end
        end

        playerA.speedX,playerB.speedX = playerB.speedX,playerA.speedX

        if not onlinePlayPlayers.ownsPlayer(playerA) then
            playerA.speedX = playerA.speedX*0.25
        elseif not onlinePlayPlayers.ownsPlayer(playerB) then
            playerB.speedX = playerB.speedX*0.25
        end

        playerA:mem(0x136,FIELD_BOOL,true)
        playerB:mem(0x136,FIELD_BOOL,true)

        if onlinePlayPlayers.canMakeSound(playerA) or onlinePlayPlayers.canMakeSound(playerB) then
            SFX.play(10)
        end

        return
    end

    -- More dramatic push
    local pushDirection

    if math.abs((playerA.x + playerA.width) - (playerB.x + playerB.width*0.5)) < 2 then
        pushDirection = RNG.randomInt(0,1)*2 - 1
    elseif (playerA.x + playerA.width*0.5) > (playerB.x + playerB.width*0.5) then
        pushDirection = 1
    else
        pushDirection = -1
    end

    if onlinePlayPlayers.ownsPlayer(playerA) then
        playerA:mem(0x138,FIELD_FLOAT,pushDirection)
    end

    if onlinePlayPlayers.ownsPlayer(playerB) then
        playerB:mem(0x138,FIELD_FLOAT,-pushDirection)
    end


    if onlinePlayPlayers.canMakeSound(playerA) or onlinePlayPlayers.canMakeSound(playerB) then
        SFX.play(10)
    end
end

local function handlePlayerInteraction(playerA)
    if not hasPlayerInteraction(playerA) then
        return
    end

    for _,playerB in ipairs(Player.getIntersecting(playerA.x,playerA.y,playerA.x + playerA.width,playerA.y + playerA.height)) do
        if playerA ~= playerB and (playerA.idx < playerB.idx or onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE) and hasPlayerInteraction(playerB) then
            playerToPlayerCollision(playerA,playerB)
        end
    end
end


local function getRespawnDuration()
    return battlePlayer.respawnDurations[battleGeneral.mode] or battlePlayer.respawnDurations.default
end

local function shouldDisplayPlayerName(p)
    if onlinePlay.currentMode == onlinePlay.MODE_OFFLINE then
        return false
    end

    local data = battlePlayer.getPlayerData(p)

    if dontDisplayNameStates[p.forcedState] or data.isDead then
        return false
    end

    if booMushroom.isActive(p) and not battlePlayer.playersAreOnSameTeam(p.idx,battleCamera.onlineFollowedPlayerIdx) then
        return false
    end

    if lunatime.tick() <= 10 then
        return false
    end

    return true
end

local function doForfeitExplosion(p)
    if onlinePlayPlayers.ownsPlayer(p) then
        Defines.earthquake = 8
    end

    Effect.spawn(69,p.x + p.width*0.5,p.y + p.height*0.5)
    SFX.play(43)
end


function battlePlayer.onTick()
    for _,p in ipairs(Player.get()) do
        local data = battlePlayer.getPlayerData(p)

        -- Custom player-to-player interaction
        p.noplayerinteraction = true
        handlePlayerInteraction(p)

        -- This fixes an issue where, with > 2 players, everyone will be teleported when going through a warp.
        handlePlayerWarping(p)

        -- Limit the number of hearts for Toad, Peach and Link
        if p:mem(0x16,FIELD_WORD) > battlePlayer.maxHearts then
            p:mem(0x16,FIELD_WORD,battlePlayer.maxHearts)
        end

        -- Disable the normal reserve box drop
        p:mem(0x130,FIELD_BOOL,false)

        -- Handling for custom ice block stuff
        if data.iceBlockNPC ~= nil then
            if not data.iceBlockNPC.isValid or data.iceBlockNPC.id ~= 263 then
                if p.forcedState == FORCEDSTATE_SWALLOWED then
                    p.forcedState = FORCEDSTATE_NONE
                    p.forcedTimer = 0
                    p:mem(0xBA,FIELD_WORD,0)
                end

                data.iceBlockNPC = nil
            end
        end

        -- Name fading in/out
        if shouldDisplayPlayerName(p) then
            data.nameOpacity = math.min(1,data.nameOpacity + 0.1)
        else
            data.nameOpacity = math.max(0,data.nameOpacity - 0.1)
        end

        -- Reset lost stars amount
        data.lostStarsAmount = 0
    end

    -- Reset player "templates" so that they don't have a powerup
    for i = 1,5 do
        local p = Player(1000 + i)

        p.reservePowerup = 0
        p.powerup = PLAYER_SMALL
        p.mount = 0
        p.mountColor = 0
        p:mem(0x16,FIELD_WORD,0)
    end
end


function battlePlayer.onTickEnd()
    for _,p in ipairs(Player.get()) do
        local data = battlePlayer.getPlayerData(p)

        -- Forfeiting
        if data.forfeited and not data.isDead then
            if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
                playerForfeitCommand:send(0)
            end

            data.lives = 1

            battlePlayer.onPlayerKillCustom({cancelled = false},p)
            customKillPlayer(p)
            doForfeitExplosion(p)
        end

        -- Death/respawning behaviour
        if data.respawnTimer > 0 then
            data.respawnTimer = data.respawnTimer - 1

            local t = data.respawnTimer/data.respawnDuration

            local respawnPoint = battlePlayer.getStartPoint(p.idx)
            local respawnSection = Section.getIdxFromCoords(respawnPoint.x - p.width*0.5,respawnPoint.y - p.height,p.width,p.height)

            if respawnSection == data.deathStartSection then
                local moveTime = 1 - math.clamp(math.invlerp(16,data.respawnDuration - 8,data.respawnTimer),0,1)
                local easedTime = easing.inOutQuad(moveTime,0,1,1)

                p.x = math.lerp(data.deathStart.x,respawnPoint.x,easedTime) - p.width*0.5
                p.y = math.lerp(data.deathStart.y,respawnPoint.y,easedTime) - p.height
            else
                if data.respawnTimer <= 16 then
                    p.x = respawnPoint.x - p.width*0.5
                    p.y = respawnPoint.y - p.height
                    p.section = respawnSection
                end
            end


            if t <= 0 then
                p.forcedState = FORCEDSTATE_NONE
                p.forcedTimer = 0

                data.respawnTimer = 0
                data.isDead = false

                p:mem(0x140,FIELD_WORD,150)

                if (p.x + p.width*0.5) > (p.sectionObj.boundary.left + p.sectionObj.boundary.right)*0.5 then
                    p.direction = DIR_LEFT
                else
                    p.direction = DIR_RIGHT
                end

                local e = Effect.spawn(131,p.x + p.width*0.5,p.y + p.height*0.5)

                e.x = e.x - e.width *0.5
                e.y = e.y - e.height*0.5

                SFX.play(34)
            end
        elseif data.isDead then
            p.x = data.deathStart.x - p.width*0.5
            p.y = data.deathStart.y - p.height

            data.deathTimer = data.deathTimer + 1
            data.isActive = (data.deathTimer <= 100)
        end

        if data.isDead then
            p.forcedState = FORCEDSTATE_SWALLOWED
            p.forcedTimer = p.idx
            p:mem(0xBA,FIELD_WORD,p.idx)
        end
    end

    if not battleMessages.victoryActive and onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT then
        local winnerIdx = findWinningPlayer()

        if winnerIdx ~= nil then
            battleMessages.startVictory(winnerIdx)
        end
    end


    if mutedLinkHitSound then
        Audio.sounds[89].muted = false
        mutedLinkHitSound = false
    end
end


local function getPlayerPriority(p)
    if p.forcedState == FORCEDSTATE_PIPE then
        return -75
    elseif p.mount == MOUNT_CLOWNCAR then
        return -35
    else
        return -25
    end
end

local function renderPlayerOutline(p,camIdx)
    if invisiblePlayerStates[p.forcedState] or p:mem(0x142,FIELD_BOOL) or p.deathTimer > 0 or p:mem(0x13C,FIELD_BOOL) or p:mem(0x0C,FIELD_BOOL) then
        return
    end

    if booMushroom.isActive(p) and not battleCamera.cameraIsFocusedOnPlayer(camIdx,p.idx) and not battlePlayer.playersAreOnSameTeam(p.idx,battleCamera.onlineFollowedPlayerIdx) then
        return
    end

    -- Decide what shader and color to use
    local gradientColors = battlePlayer.getColorGradient(p.idx)
    local color

    local uniforms = {imageSize = vector(playerBuffer.width,playerBuffer.height)}
    local shader

    if gradientColors == nil then
        if playerOutlineShader == nil then
            playerOutlineShader = Shader.fromFile(nil,"resources/outline.frag",{THICKNESS = battlePlayer.outlineThickness})
        end

        color = battlePlayer.getColor(p.idx).. 0.5
        shader = playerOutlineShader

        if booMushroom.isActive(p) then
            color.a = color.a*0.5
        end
    else
        if gradientOutlineShader == nil then
            gradientOutlineShader = Shader.fromFile(nil,"resources/outlineGradient.frag",{THICKNESS = battlePlayer.outlineThickness,MAX_COLORS = maxGradientColors})
        end

        shader = gradientOutlineShader

        uniforms.baseX = p.x + p.width*0.5 - camera.x
        uniforms.baseY = p.y + p.height - camera.y
        uniforms.time = lunatime.drawtick()

        uniforms.colorCount = #gradientColors
        uniforms.colors = {}

        for colorIndex,color in ipairs(gradientColors) do
            uniforms.colors[colorIndex*3 - 2] = color.r
            uniforms.colors[colorIndex*3 - 1] = color.g
            uniforms.colors[colorIndex*3] = color.b
        end

        for colorIndex = (uniforms.colorCount*3 + 1),maxGradientColors*3 do
            uniforms.colors[colorIndex] = 0
        end

        if booMushroom.isActive(p) then
            color = Color.white.. 0.5
        end
    end

    -- Render it to a buffer
    local priority = math.min(-66, getPlayerPriority(p)) - 0.01
    local frame

    if p.frame == 15 and p.forcedState == FORCEDSTATE_PIPE and p.character == CHARACTER_LINK then
        frame = 1 -- Link is, for some reason, in frame 15 when going through a vertical pipe
    end

    if p.data.booMushroom ~= nil then
        frame = p.data.booMushroom.restoreFrame or frame
    end

    playerBuffer:clear(priority)

    p:render{
        target = playerBuffer,priority = priority,sceneCoords = false,
        frame = frame,
        x = (playerBuffer.width  - p.width )*0.5,
        y = (playerBuffer.height - p.height)*0.5,
    }

    -- Render that bufer, now with an outline effect
    Graphics.drawBox{
        texture = playerBuffer,color = color,priority = priority,
        centred = true,sceneCoords = true,
        x = math.floor(p.x + 0.5) + p.width*0.5,
        y = math.floor(p.y + 0.5) + p.height*0.5,
        
        shader = shader,uniforms = uniforms,
    }
end


local simpleOutlineShader

function battlePlayer.renderOutlinedPlayerHead(args)
    if simpleOutlineShader == nil then
        simpleOutlineShader = Shader.fromFile(nil,"resources/simpleOutline.frag")
    end

    local image = battlePlayer.getPlayerHead(Player(args.playerIdx))

    local color = args.color or Color.white
    local outlineColor = color*(battlePlayer.getColor(args.playerIdx).. (args.outlineOpacity or 0.5))

    local width = image.width + 4
    local height = image.height + 4

    Graphics.drawBox{
        texture = image,priority = args.priority,target = args.target,
        color = color,
        centred = true,

        width = width*(args.scaleX or args.scale or 1),
        height = height*(args.scaleY or args.scale or 1),
        sourceWidth = width,sourceHeight = height,
        sourceX = -2,sourceY = -2,
        x = args.x,y = args.y,

        shader = simpleOutlineShader,uniforms = {
            outlineColor = outlineColor,
            imageSize = vector(image.width,image.height),
        },
    }
end


local function renderPlayerName(p)
    local data = battlePlayer.getPlayerData(p)

    if data.nameOpacity <= 0 then
        return
    end

    -- Create layout if necessary
    local nameText = battlePlayer.getName(p.idx)

    if data.nameLayout == nil or data.nameText ~= nameText then
        data.nameLayout = textplus.layout(nameText,nil,battlePlayer.nameTextFormat)
        data.nameText = nameText
    end

    -- Render
    local color = battlePlayer.getColor(p.idx):lerp(Color.white,0.5)*data.nameOpacity

    textplus.render{
        layout = data.nameLayout,color = color,
        priority = 1,sceneCoords = true,

        x = math.floor(p.x + (p.width - data.nameLayout.width)*0.5),
        y = math.floor(p.y - 16 - data.nameLayout.height*0.5),
    }
end


local function drawForPlayer(p,camIdx)
    local data = battlePlayer.getPlayerData(p)
    local cam = Camera(camIdx)

    if data.isActive then
        if p.x < (cam.x + cam.width) and (p.x + p.width) > cam.x and p.y < (cam.y + cam.height) and (p.y + p.height) > cam.y then
            -- Outline
            if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
                renderPlayerOutline(p,camIdx)
            end
        end

        -- Name
        if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and p.idx ~= battleCamera.onlineFollowedPlayerIdx and onlinePlay.isConnected(p.idx) then
            renderPlayerName(p)
        end
    end
end


function battlePlayer.onCameraDraw(camIdx)
    -- Draw stuff for each player
    for _,p in ipairs(Player.get()) do
        drawForPlayer(p,camIdx)
    end
end


local oldEndState

function battlePlayer.onDraw()
    -- Check if everyone is using the same character
    local sharedCharacter

    if onlinePlay.currentMode == onlinePlay.MODE_OFFLINE then
        for _,p in ipairs(Player.get()) do
            local data = battlePlayer.getPlayerData(p)

            if data.isActive then
                if sharedCharacter ~= nil and sharedCharacter ~= p.character then
                    sharedCharacter = nil
                    break
                else
                    sharedCharacter = p.character
                end
            end
        end
    else
        sharedCharacter = Player(onlinePlay.playerIdx).character
    end

    -- Make character block animation still happen if someone's playing as that character
    for _,blockID in ipairs(battlePlayer.characterBlocksList) do
        local characterID = battlePlayer.characterBlocksMap[blockID]
        local frame

        if sharedCharacter == characterID then
            frame = 4
        else
            frame = (lunatime.drawtick()/8) % 4
        end

        blockutils.setBlockFrame(blockID,frame)
    end

    -- Fixes some very odd issues
    if oldEndState == nil then
        oldEndState = Level.endState()
        Level.endState(2)
    end
end

function battlePlayer.onDrawEnd()
    if oldEndState ~= nil then
        Level.endState(oldEndState)
        oldEndState = nil
    end
end


function perPlayerCostumes.getTintColor(p,camIdx)
    -- Transparency for the boo mushroom
    if booMushroom.isActive(p) then
        return Color(1,1,1,0.6)
    end

    -- Make players on the opposing team darker
    if battlePlayer.teamsAreEnabled() and not battlePlayer.playersAreOnSameTeam(p.idx,battleCamera.onlineFollowedPlayerIdx) and not battleGeneral.isInHub then
        return Color(0.6,0.6,0.6)
    end

    return nil
end

function perPlayerCostumes.getIsInvisible(p,camIdx)
    -- Invisiblity for the boo mushroom
    if booMushroom.isActive(p) and not booMushroom.booMushroomedPlayerShouldBeVisible(p,camIdx) then
        return true
    end

    return false
end


-- Harm/death stuff
do
    local notNoHurtNPCs = table.map{171,266,292,45}

    local function findHarmCulprit(p)
        -- NPCs
        local col = Colliders.getHitbox(p)

        col.x = col.x - 8
        col.y = col.y - 8
        col.width = col.width + 16
        col.height = col.height + 16

        for _,n in ipairs(Colliders.getColliding{a = col,btype = Colliders.NPC}) do
            local config = NPC.config[n.id]

            if (not config.nohurt or config.isvegetable or notNoHurtNPCs[n.id]) and n:mem(0x130,FIELD_WORD) ~= p.idx then
                return n 
            end
        end

        -- Players
        for _,o in ipairs(Player.get()) do
            if Colliders.slash(o,col) or Colliders.downSlash(o,col) or (Colliders.collide(o,col) and (o:mem(0x3E,FIELD_BOOL) or o.hasStarman)) then
                return o
            end
        end

        return nil
    end

    local function canClaimPlayerHarm(p,culprit,harmType)
        -- It's ourselves!
        if p.idx == onlinePlay.playerIdx then
            return true
        end

        if type(culprit) == "Player" then
            -- It's not us getting hurt, but we ARE evil
            if culprit.idx == onlinePlay.playerIdx then
                return true
            end
        elseif type(culprit) == "NPC" then
            -- Some projectiles (like fireballs) should DEFINITELY be defender-favoured
            if battlePlayer.defenderFavouredProjectileMap[culprit.id] then
                return false
            end

            -- It's not us getting hurt, but we have an evil lackey
            if culprit:mem(0x12C,FIELD_WORD) == onlinePlay.playerIdx
            or culprit:mem(0x132,FIELD_WORD) == onlinePlay.playerIdx
            then
                return true
            end
        end

        return false
    end

    local function getHarmType(p,culprit)
        -- Fire ball
        if type(culprit) == "NPC" and culprit.id == 13 and battleGeneral.mode ~= battleGeneral.gameMode.CLASSIC then
            return battlePlayer.HARM_TYPE.SMALL_DAMAGE
        end

        -- Ice ball
        if type(culprit) == "NPC" and culprit.id == 265 and not p:mem(0x0C,FIELD_BOOL) then
            return battlePlayer.HARM_TYPE.FREEZE
        end

        return battlePlayer.HARM_TYPE.NORMAL
    end

    local function getPlayerIndexResponsibleForHarm(p,culprit)
        if type(culprit) == "Player" then
            return culprit.idx
        elseif type(culprit) == "NPC" then
            local ownerPlayerIdx = culprit:mem(0x132,FIELD_WORD)

            if ownerPlayerIdx > 0 then
                return ownerPlayerIdx
            end

            local holdPlayerIdx = culprit:mem(0x12C,FIELD_WORD)

            if holdPlayerIdx > 0 then
                return holdPlayerIdx
            end
        end

        return 0
    end

    local function harmIsFriendlyFire(p,culprit)
        if not battlePlayer.teamsAreEnabled() then
            return false
        end

        local culpritPlayerIdx = getPlayerIndexResponsibleForHarm(p,culprit)

        return (culpritPlayerIdx > 0 and culpritPlayerIdx ~= p.idx and battlePlayer.playersAreOnSameTeam(p.idx,culpritPlayerIdx))
    end


    function battlePlayer.harmPlayer(p,harmType)
        local data = battlePlayer.getPlayerData(p)

        if p.forcedState ~= FORCEDSTATE_NONE and p:mem(0x140,FIELD_WORD) ~= 0 or p.hasStarman then
            return
        end

        harmType = harmType or battlePlayer.HARM_TYPE.NORMAL

        -- Event
        local eventObj = {cancelled = false}
        battlePlayer.onPlayerHarmCustom(eventObj,p,harmType)

        if eventObj.cancelled then
            return
        end

        battlePlayer.onPostPlayerHarmCustom(p,harmType)

        -- Command
        if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and not data.dontSendHarmCommand then
            playerHarmCommand:send(0, p.idx,harmType)
        end

        -- Hub damage/damage after victory
        if (battleGeneral.mode == battleGeneral.gameMode.HUB or battleMessages.victoryActive) and harmType ~= battlePlayer.HARM_TYPE.FREEZE then
            p:mem(0x140,FIELD_WORD,50)
            SFX.play(54)

            return
        end


        -- "Small" damage, don't lose powerups
        if harmType == battlePlayer.HARM_TYPE.SMALL_DAMAGE then
            -- Invincibility frames
            p:mem(0x140,FIELD_WORD,p:mem(0x140,FIELD_WORD) + 100)
            SFX.play(76)

            -- Lose stars
            battleStars.lose(p,1)
            return
        end

        -- Freeze!
        if harmType == battlePlayer.HARM_TYPE.FREEZE then
            if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and onlinePlay.playerIdx ~= p.idx then
                return
            end

            if data.iceBlockNPC ~= nil and data.iceBlockNPC.isValid then
                return
            end

            local iceWidth = math.floor(p.width*1.25*0.5 + 0.5)*2
            local iceHeight = p.height

            local iceBlock = NPC.spawn(263,p.x + (p.width - iceWidth)*0.5,p.y + p.height - iceHeight,p.section,false,false)

            iceBlock.width = iceWidth
            iceBlock.height = iceHeight

            iceBlock.ai1 = 959 -- NPC ID in the block
            iceBlock.ai2 = 0
            iceBlock.ai3 = 1

            iceBlock.data.frozenPlayerIdx = p.idx
            iceBlock.data.shakeTimer = 0
            iceBlock.data.shakeQueued = false
            iceBlock.data.shakeOffset = 0
            iceBlock.data.shakeCount = 0
            iceBlock.data.lifetime = 384

            data.iceBlockNPC = iceBlock

            if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
                onlinePlayNPC.tryClaimNPC(iceBlock)
            end

            p.forcedState = FORCEDSTATE_SWALLOWED
            p.forcedTimer = p.idx
            p:mem(0xBA,FIELD_WORD,p.idx)

            return
        end

        -- Lose stars
        battleStars.lose(p)

        -- Hurt normally
        data.allowedToHarm = true
        p:harm()
        data.allowedToHarm = false
    end

    function battlePlayer.onPlayerHarm(eventObj,p)
        if eventObj.cancelled or p.hasStarman then
            return
        end

        local data = battlePlayer.getPlayerData(p)

        if data.allowedToHarm then
            return
        end

        eventObj.cancelled = true


        local culprit = findHarmCulprit(p)
        local harmType = getHarmType(p,culprit)

        if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and not canClaimPlayerHarm(p,culprit,harmType) then
            return
        end

        if harmIsFriendlyFire(p,culprit) then
            if type(culprit) == "Player" and not Audio.sounds[89].muted and not mutedLinkHitSound then
                Audio.sounds[89].muted = true
                mutedLinkHitSound = true
            end

            return
        end

        battlePlayer.harmPlayer(p,harmType)
    end


    function customKillPlayer(p)
        local data = battlePlayer.getPlayerData(p)
        
        battlePlayer.onPostPlayerKillCustom(p)

        -- Spawn death effect
        --[[local e = Effect.spawn(battlePlayer.playerDeathEffects[p.character],p.x + p.width*0.5,p.y + p.height*0.5)

        if p.character == CHARACTER_LINK then
            e.direction = p.direction
            e.speedX = -2*e.direction
        end]]

        perPlayerCostumes.spawnDeathEffect(p,p.x + p.width*0.5,p.y + p.height*0.5)

        -- Drop stuff
        if p:mem(0xB8,FIELD_WORD) > 0 then -- yoshi NPC
            local npc = NPC(p:mem(0xB8,FIELD_WORD) - 1)

            npc.x = p.x + p:mem(0x6E,FIELD_WORD) - npc.width*0.5 + 16
            npc.y = p.y + p:mem(0x70,FIELD_WORD) - npc.height*0.5 + 16
            npc:mem(0x138,FIELD_WORD,0)
            npc:mem(0x13C,FIELD_DFLOAT,0)
            npc:mem(0x144,FIELD_WORD,0)
            npc:mem(0x124,FIELD_BOOL,true)

            p:mem(0xB8,FIELD_WORD,0)
        end

        if p:mem(0xBA,FIELD_WORD) > 0 and p:mem(0xBA,FIELD_WORD) ~= p.idx then -- yoshi player
            local heldPlayer = Player(p:mem(0xBA,FIELD_WORD))

            heldPlayer.x = p.x + p:mem(0x6E,FIELD_WORD) - heldPlayer.width*0.5 + 16
            heldPlayer.y = p.y + p:mem(0x70,FIELD_WORD) - heldPlayer.height*0.5 + 16
            heldPlayer.y = math.min(heldPlayer.y,p.y + p.height - heldPlayer.height)

            heldPlayer.forcedState = FORCEDSTATE_NONE
            heldPlayer.forcedTimer = 0
            heldPlayer.speedX = 0
            heldPlayer.speedY = 0
            heldPlayer.direction = p.direction

            p:mem(0xBA,FIELD_WORD,0)
        end

        if p.holdingNPC ~= nil then
            p.holdingNPC:mem(0x12C,FIELD_WORD,0)
        end

        p:mem(0x154,FIELD_WORD,0) -- held NPC


        -- Actually die/respawn
        battlePlayer.reset(p,false)

        if data.lives > 1 or data.lives < 0 then
            data.respawnDuration = getRespawnDuration()
            data.respawnTimer = data.respawnDuration
            data.lives = data.lives - 1
        else
            data.lives = 0
            data.respawnTimer = 0
        end

        p.forcedState = FORCEDSTATE_SWALLOWED
        p.forcedTimer = p.idx
        p:mem(0xBA,FIELD_WORD,p.idx)

        data.deathStart = vector(p.x + p.width*0.5,p.y + p.height)
        data.deathStartSection = p.section
        data.deathTimer = 0
        data.isDead = true
        data.nameOpacity = 0

        SFX.play(54)

        if data.lives == 0 and onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
            local name = battlePlayer.getName(p.idx)

            if data.forfeited then
                battleMessages.spawnStatusMessage(textFiles.funcs.replace(textFiles.battleMessages.forfeited,{NAME = name}),p.idx)
            else
                battleMessages.spawnStatusMessage(textFiles.funcs.replace(textFiles.battleMessages.eliminated,{NAME = name}),p.idx)
            end
        end

        if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and onlinePlay.playerIdx == p.idx and not data.forfeited then
            battleGeneral.saveData.onlineDeaths = battleGeneral.saveData.onlineDeaths + 1
        end
    end


    function battlePlayer.onPlayerKill(eventObj,p)
        if eventObj.cancelled then
            return
        end

        eventObj.cancelled = true

        local data = battlePlayer.getPlayerData(p)

        if battleGeneral.mode == battleGeneral.gameMode.HUB then
            if p.y >= p.sectionObj.boundary.bottom+64 then
                if onlinePlay.currentMode == onlinePlay.MODE_OFFLINE or battleCamera.onlineFollowedPlayerIdx == p.idx or battleCamera.isOnScreen(p.x,p.y - 128,p.width,p.height) then
                    SFX.play(24)
                end

                p.speedY = -20
            end
            
            return
        end

        -- Call event
        local customEvent = {cancelled = false}
        battlePlayer.onPlayerKillCustom(customEvent,p,culprit)

        if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
            if p.idx == onlinePlay.playerIdx then
                -- If this *is* us, send a message to everyone.
                if customEvent.cancelled then
                    return
                end

                playerDeathCommand:send(0, data.lives)
            else
                -- If this isn't us, don't do anything. The player will send a message for it.
                return
            end
        elseif customEvent.cancelled then
            return
        end

        -- Lose stars
        local loseAmount = math.max(3,math.floor((data.stars + data.lostStarsAmount)*1/3 + 0.5)) - data.lostStarsAmount
        
        battleStars.lose(p,loseAmount)

        -- Overwritten death behaviour
        customKillPlayer(p)
    end
end


function battlePlayer.onBlockHit(eventObj,b,fromTop,playerObj)
    local characterID = battlePlayer.characterBlocksMap[b.id]

    if characterID ~= nil and playerObj ~= nil then
        -- Handle character transforming manually so that multiple players can use the same character
        if playerObj.character ~= characterID then
            playerObj:transform(characterID,true)
        end

        blockutils.bump(b)

        eventObj.cancelled = true
        return
    end
end


function battlePlayer.onInitAPI()
    registerEvent(battlePlayer,"onStart")
    registerEvent(battlePlayer,"onStart","onStartLate",false)
    registerEvent(battlePlayer,"onExitLevel")

    registerEvent(battlePlayer,"onInputUpdate")

    registerEvent(battlePlayer,"onTick")
    registerEvent(battlePlayer,"onTickEnd")

    registerEvent(battlePlayer,"onDraw")
    registerEvent(battlePlayer,"onCameraDraw","onCameraDraw",false)
    registerEvent(battlePlayer,"onDrawEnd")

    registerEvent(battlePlayer,"onPlayerHarm")
    registerEvent(battlePlayer,"onPlayerKill","onPlayerKill",false)

    registerEvent(battlePlayer,"onBlockHit")


    battleGeneral = require("scripts/battleGeneral")
    battleCamera = require("scripts/battleCamera")
    battleMessages = require("scripts/battleMessages")
    battleStars = require("scripts/battleStars")
    battleItems = require("scripts/battleItems")
    battleOptions = require("scripts/battleOptions")

    onlinePlay = require("scripts/onlinePlay")
    onlinePlayPlayers = require("scripts/onlinePlay_players")
    onlinePlayNPC = require("scripts/onlinePlay_npc")
    onlineChat = require("scripts/onlineChat")

    booMushroom = require("scripts/booMushroom")


    registerCustomEvent(battlePlayer,"onPostPlayerKillCustom")
    registerCustomEvent(battlePlayer,"onPostPlayerHarmCustom")
    registerCustomEvent(battlePlayer,"onPlayerKillCustom")
    registerCustomEvent(battlePlayer,"onPlayerHarmCustom")
    registerCustomEvent(battlePlayer,"onPlayerStomped")


    battlePlayer.respawnDurations = {
        default = 80,
        [battleGeneral.gameMode.STARS] = 160,
        [battleGeneral.gameMode.STONE] = 128,
    }

    battleGeneral.gameData.playerCount = battleGeneral.gameData.playerCount or 1
    battleGeneral.saveData.playerCharacters = battleGeneral.saveData.playerCharacters or {}
    battleGeneral.saveData.playerCostumes = battleGeneral.saveData.playerCostumes or {}
    --battleGeneral.saveData.characterCostumes = battleGeneral.saveData.characterCostumes or {}

    battleGeneral.gameData.playerCharacters = battleGeneral.gameData.playerCharacters or {}
    battleGeneral.gameData.playerCostumes = battleGeneral.gameData.playerCostumes or {}
    --battleGeneral.gameData.characterCostumes = battleGeneral.gameData.characterCostumes or {}

    battleGeneral.gameData.teamsEnabled = battleGeneral.gameData.teamsEnabled or false
    battleGeneral.gameData.playerTeams = battleGeneral.gameData.playerTeams or {}
    battleGeneral.gameData.decidedPlayerTeams = battleGeneral.gameData.decidedPlayerTeams or {}


    playerDeathCommand = onlinePlay.createCommand("battle_player_death",onlinePlay.IMPORTANCE_MAJOR)
    playerHarmCommand = onlinePlay.createCommand("battle_player_harm",onlinePlay.IMPORTANCE_MAJOR)
    playerStompCommand = onlinePlay.createCommand("battle_player_stomp",onlinePlay.IMPORTANCE_MAJOR)
    playerPushCommand = onlinePlay.createCommand("battle_player_push",onlinePlay.IMPORTANCE_MINOR)
    playerForfeitCommand = onlinePlay.createCommand("battle_player_forfeit",onlinePlay.IMPORTANCE_MAJOR)
    setTeamsCommand = onlinePlay.createCommand("battle_player_teams",onlinePlay.IMPORTANCE_MAJOR)

    function playerDeathCommand.onReceive(sourcePlayerIdx, lives)
        local p = Player(sourcePlayerIdx)
        local data = battlePlayer.getPlayerData(p)

        data.lives = lives

        battlePlayer.onPlayerKillCustom({cancelled = false},p)
        customKillPlayer(p)
    end

    function playerHarmCommand.onReceive(sourcePlayerIdx, playerIdx,harmType)
        local p = Player(playerIdx)
        local data = battlePlayer.getPlayerData(p)

        data.dontSendHarmCommand = true
        battlePlayer.harmPlayer(p,harmType)
        data.dontSendHarmCommand = false
    end

    function playerStompCommand.onReceive(sourcePlayerIdx, playerIdx)
        local stompingPlayer = Player(sourcePlayerIdx)
        local stompedPlayer = Player(playerIdx)

        stompReaction(stompedPlayer,stompingPlayer)
    end

    function playerPushCommand.onReceive(sourcePlayerIdx, pushedPlayerIdx,pushSpeed)
        local pushingPlayer = Player(sourcePlayerIdx)
        local pushedPlayer = Player(pushedPlayerIdx)

        pushedPlayer.speedX = pushSpeed
        pushedPlayer:mem(0x136,FIELD_BOOL,true)

        if onlinePlayPlayers.canMakeSound(pushingPlayer) or onlinePlayPlayers.canMakeSound(pushedPlayer) then
            SFX.play(10)
        end
    end

    function playerForfeitCommand.onReceive(sourcePlayerIdx)
        local p = Player(sourcePlayerIdx)
        local data = battlePlayer.getPlayerData(p)

        data.forfeited = true
        data.lives = 1

        battlePlayer.onPlayerKillCustom({cancelled = false},p)
        customKillPlayer(p)
        doForfeitExplosion(p)
    end

    function setTeamsCommand.onReceive(sourcePlayerIdx, playerTeams)
        if sourcePlayerIdx ~= onlinePlay.hostPlayerIdx then
            return
        end

        battleGeneral.gameData.teamsEnabled = (playerTeams ~= nil)
        battleGeneral.gameData.playerTeams = playerTeams or {}
    end


    function onlinePlay.onConnect(playerIdx)
        if playerIdx == onlinePlay.playerIdx then
            battlePlayer.saveCharacters(false)

            battleGeneral.gameData.playerCharacters = {[playerIdx] = battleGeneral.saveData.playerCharacters[1]}
            battleGeneral.gameData.playerCostumes = {[playerIdx] = {}}

            for character = 1,5 do
                battleGeneral.gameData.playerCostumes[playerIdx][character] = battleGeneral.saveData.playerCostumes[playerIdx][character]
            end

            battlePlayer.loadCostumes(true)
        end

        if onlinePlay.currentMode == onlinePlay.MODE_HOST and playerIdx ~= onlinePlay.playerIdx then
            battlePlayer.sendTeamsUpdate()
        end

        battlePlayer.setPlayerIsActive(Player(playerIdx),true)
    end

    function onlinePlay.onDisconnect(playerIdx)
        if playerIdx == onlinePlay.playerIdx then
            --battlePlayer.saveCharacters(true)

            battleGeneral.saveData.playerCharacters[1] = Player(playerIdx).character
            battleGeneral.saveData.playerCostumes[1] = perPlayerCostumes.getAllCostumes(playerIdx)

            battleGeneral.gameData.playerCharacters = {}
            battleGeneral.gameData.playerCostumes = {}

            battlePlayer.loadCharacters(false)
            battlePlayer.loadCostumes(false)
        end

        if playerIdx > 1 then
            battlePlayer.setPlayerIsActive(Player(playerIdx),false)
            perPlayerCostumes.setAllCostumes(playerIdx,{})
        end

        battleGeneral.gameData.playerTeams[playerIdx] = nil
        battleGeneral.gameData.decidedPlayerTeams[playerIdx] = nil
    end

    function onlinePlay.onUninitialise()
        battleGeneral.gameData.teamsEnabled = false
        battleGeneral.gameData.playerTeams = {}
        battleGeneral.gameData.decidedPlayerTeams = {}
    end
end


return battlePlayer