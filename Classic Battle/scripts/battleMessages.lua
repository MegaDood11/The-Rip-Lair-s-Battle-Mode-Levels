local textplus = require("textplus")
local easing = require("ext/easing")

local textFiles = require("scripts/textFiles")

local battleGeneral,battlePlayer,onlinePlay

local battleMessages = {}


battleMessages.font = textplus.loadFont("resources/font/outlinedFont.ini")
battleMessages.textScale = 4

battleMessages.textObjects = {}


battleMessages.victoryDuration = 256
battleMessages.victoryActive = false
battleMessages.victoryTimer = 0

battleMessages.victoriousPlayerIdx = 0


battleMessages.activeStatusText = nil


battleMessages.priority = 6.25


local victoryCommand

local STATE = {
    DELAY  = 0,
    ENTER  = 1,
    STAY   = 2,
    FADE   = 3,
    DELETE = 4,
}


function battleMessages.spawnText(args)
    local screenWidth,screenHeight = battleGeneral.getScreenSize()

    local text = {}


    text.message = args.message

    text.color = args.color or Color.white
    text.font = args.font or battleMessages.font
    text.scale = args.scale or battleMessages.textScale

    text.layout = textplus.layout(text.message,nil,{color = text.color,font = text.font,xscale = text.scale,yscale = text.scale,align = "center",plaintext = true})


    text.width = text.layout.width
    text.height = text.layout.height

    text.pivot = args.pivot or vector(0.5,0.5)

    text.goalX = args.x - text.width *text.pivot.x
    text.goalY = args.y - text.height*text.pivot.y


    if args.horizontalDirection == 1 then
        text.startX = screenWidth
    elseif args.horizontalDirection == -1 then
        text.startX = -text.width
    else
        text.startX = text.goalX
    end
    if args.verticalDirection == 1 then
        text.startY = screenHeight
    elseif args.verticalDirection == -1 then
        text.startY = -text.height
    else
        text.startY = text.goalY
    end

    text.x = text.startX
    text.y = text.startY


    text.enterTime = args.enterTime or 48
    text.stayTime = args.stayTime or 0
    text.fadeTime = args.fadeTime or 16

    text.delay = args.delay or 0

    text.opacity = 1

    if text.delay > 0 then
        text.state = STATE.DELAY
        text.timer = text.delay
    else
        text.state = STATE.ENTER
        text.timer = 0
    end

    table.insert(battleMessages.textObjects,text)

    return text
end


function battleMessages.onTick()
    for i = #battleMessages.textObjects, 1, -1 do
        local text = battleMessages.textObjects[i]
        
        text.timer = text.timer + 1

        if text.state == STATE.DELAY then
            if text.timer >= text.delay then
                text.state = STATE.ENTER
                text.timer = 0
            end
        elseif text.state == STATE.ENTER then
            text.x = easing.outElastic(text.timer,text.startX,text.goalX - text.startX,text.enterTime,nil,text.enterTime*0.8)
            text.y = easing.outElastic(text.timer,text.startY,text.goalY - text.startY,text.enterTime,nil,text.enterTime*0.8)

            if text.timer >= text.enterTime then
                text.state = STATE.STAY
                text.timer = 0

                text.x = text.goalX
                text.y = text.goalY
            end
        elseif text.state == STATE.STAY then
            if text.stayTime > 0 and text.timer >= text.stayTime then
                text.state = STATE.FADE
                text.timer = 0
            end
        elseif text.state == STATE.FADE then
            text.opacity = 1 - text.timer/text.fadeTime

            if text.opacity <= 0 then
                text.state = STATE.DELETE
            end
        end

        if text.state == STATE.DELETE then
            table.remove(battleMessages.textObjects,i)
        end
    end

    if battleMessages.victoryActive then
        battleMessages.victoryTimer = battleMessages.victoryTimer + 1

        if onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT and battleMessages.victoryTimer >= battleMessages.victoryDuration then
            Level.load(battleGeneral.hubLevelFilename)
        end
    end
end

function battleMessages.onCameraDraw(camIdx)
    local cam = Camera(camIdx)

    for _,text in ipairs(battleMessages.textObjects) do
        textplus.render{
            layout = text.layout,priority = battleMessages.priority,
            color = Color.white*text.opacity,

            x = math.floor(text.x - cam.renderX + 0.5),
            y = math.floor(text.y - cam.renderY + 0.5),
        }
    end
end


local function yeahIThinkWeJustWon(index)
    if onlinePlay.currentMode == onlinePlay.MODE_OFFLINE then
        return false
    end

    if battlePlayer.teamsAreEnabled() then
        return (index == battlePlayer.getTeam(onlinePlay.playerIdx))
    else
        return (index == onlinePlay.playerIdx)
    end
end

local function startVictoryInternal(index)
    local screenWidth,screenHeight = battleGeneral.getScreenSize()

    if index > 0 then
        local color,name

        if battlePlayer.teamsAreEnabled() then
            color = battleGeneral.teamColors[index]:lerp(Color.white,0.5)
            name = textFiles.battleMessages.victoryTeamNames[index]
        else
            color = battlePlayer.getColor(index):lerp(Color.white,0.5)
            name = battlePlayer.getName(index)
        end

        battleMessages.spawnText{
            message = textFiles.funcs.replace(textFiles.battleMessages.victoryTop,{NAME = name}),
            color = color,delay = 0,

            x = screenWidth*0.5,y = screenHeight*0.5,
            horizontalDirection = -1,pivot = vector(0.5,1),
        }
        battleMessages.spawnText{
            message = textFiles.funcs.replace(textFiles.battleMessages.victoryBottom,{NAME = name}),
            color = color,delay = 32,

            x = screenWidth*0.5,y = screenHeight*0.5,
            horizontalDirection = 1,pivot = vector(0.5,0),
        }

        SFX.play("Battle Mode Winner.spc")
    else
        battleMessages.spawnText{
            message = textFiles.battleMessages.victoryDraw,
            color = Color.lightgrey,delay = 0,

            x = screenWidth*0.5,y = screenHeight*0.5,
            horizontalDirection = -1,pivot = vector(0.5,0.5),
        }

        SFX.play(Misc.resolveSoundFile("resources/battleDraw"))
    end

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and battleGeneral.mode >= 0 then
        if yeahIThinkWeJustWon(index) then
            battleGeneral.saveData.onlineVictoriesByMode[battleGeneral.mode] = (battleGeneral.saveData.onlineVictoriesByMode[battleGeneral.mode] or 0) + 1
        end

        battleGeneral.saveData.onlineGamesByMode[battleGeneral.mode] = (battleGeneral.saveData.onlineGamesByMode[battleGeneral.mode] or 0) + 1
    end

    battleMessages.victoryActive = true
    battleMessages.victoryTimer = 0
    
    battleMessages.victoriousPlayerIdx = index

    battleGeneral.gameData.lastVictoriousPlayers = {}

    if battlePlayer.teamsAreEnabled() then
        for _,user in ipairs(onlinePlay.getUsers()) do
            if battlePlayer.getTeam(user.playerIdx) == index then
                table.insert(battleGeneral.gameData.lastVictoriousPlayers,user.playerIdx)
            end
        end
    elseif index > 0 then
        table.insert(battleGeneral.gameData.lastVictoriousPlayers,index)
    end


    Audio.SeizeStream(-1)
    Audio.MusicStop()
end

function battleMessages.startVictory(index)
    if battleMessages.victoryActive then
        return
    end
    
    if onlinePlay.currentMode == onlinePlay.MODE_HOST then
        victoryCommand:send(0, index)
    elseif onlinePlay.currentMode == onlinePlay.MODE_CLIENT then
        error("Cannot start a victory as a client",2)
    end

    startVictoryInternal(index)
end


function battleMessages.spawnStatusMessage(message,color)
    if type(color) == "number" then
        -- Player color
        color = battlePlayer.getColor(color):lerp(Color.white,0.5)
    end

    local screenWidth,screenHeight = battleGeneral.getScreenSize()

    if battleMessages.activeStatusText ~= nil and battleMessages.activeStatusText.opacity == 1 then
        --battleMessages.activeStatusText.state = STATE.DELETE
        battleMessages.activeStatusText.state = STATE.FADE
        battleMessages.activeStatusText.timer = 0
    end

    battleMessages.activeStatusText = battleMessages.spawnText{
        message = message,color = color,

        stayTime = 64,scale = 2,

        x = screenWidth*0.5,y = screenHeight - 16,
        verticalDirection = 1,pivot = vector(0.5,1),
    }
end


function battleMessages.onInitAPI()
    registerEvent(battleMessages,"onTick")
    registerEvent(battleMessages,"onCameraDraw")
    registerEvent(battleMessages,"onExitLevel")

    battleGeneral = require("scripts/battleGeneral")
    battlePlayer = require("scripts/battlePlayer")
    onlinePlay = require("scripts/onlinePlay")


    victoryCommand = onlinePlay.createCommand("battle_victory",onlinePlay.IMPORTANCE_MAJOR)

    function victoryCommand.onReceive(sourcePlayerIdx, winningIdx)
        if onlinePlay.currentMode == onlinePlay.MODE_HOST or sourcePlayerIdx ~= onlinePlay.hostPlayerIdx then
            return
        end

        startVictoryInternal(winningIdx)
    end
end


return battleMessages