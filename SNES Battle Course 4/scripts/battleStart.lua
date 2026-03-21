local textFiles = require("scripts/textFiles")
local utf8 = require("scripts/utf8")

local textplus = require("textplus")
local easing = require("ext/easing")

local battleStart = {}

local battleGeneral,battleHUD,battleCamera,battleMenu,onlinePlay
local bannedCharacters


battleStart.STATE = {
    INACTIVE  = 0,
    QUEUED    = 1,
    FLY_IN    = 2,
    WAIT      = 3,
    READY     = 4,
    COUNTDOWN = 5,
    FINISHED  = 6,
    FLY_OFF   = 7,
}


battleStart.lakituEnterTime = 128
battleStart.waitTime = 48
battleStart.countdownSpeed = 64
battleStart.finishedTime = 24

battleStart.unresponsiveWarningTime = lunatime.toTicks(15)


battleStart.state = battleStart.STATE.INACTIVE
battleStart.timer = 0

battleStart.backgroundFade = 0

battleStart.unresponsiveTimer = 0

battleStart.fadeIn = 0


battleStart.lakituDisabledDebug = false


local lakituImage = Graphics.loadImageResolved("resources/lakitu.png")
local lakituFrames = 4

local countdownStepSound = Misc.resolveSoundFile("resources/countdown_step")
local countdownLastSound = Misc.resolveSoundFile("resources/countdown_last")


battleStart.lakituActive = false
battleStart.lakituScene = false
battleStart.lakituX = 0
battleStart.lakituY = 0
battleStart.lakituSection = 0

battleStart.lakituStartX = 0
battleStart.lakituStartY = 0
battleStart.lakituGoalX = 0
battleStart.lakituGoalY = 0

battleStart.lakituFrame = 0

battleStart.lakituFloatTimer = 0
battleStart.lakituFloatOffset = 0

battleStart.linkFrametrapFixTimer = 0



battleStart.statusFont = textplus.loadFont("resources/font/mainFont.ini")
battleStart.statusScale = 2

battleStart.statusBoxImage = Graphics.loadImageResolved("resources/menu/box.png")
battleStart.statusBoxMarginX = 20
battleStart.statusBoxMarginY = 12

battleStart.statusGap = 16


local readyPlayerMap = {}
local sentReadyMessage = false
local hostIsReady = false

local statusMessage
local statusMessageLayout
local statusStartTime

local readyCommand


local function getLakituGoal()
    -- Not ready yet
    if not battleCamera.hasUpdatedCameras then
        return nil
    end

    -- Split screen
    if battleCamera.isSplitScreen() then
        local screenWidth,screenHeight = battleGeneral.getScreenSize()

        return screenWidth*0.5,screenHeight*0.5,-lakituImage.height*0.5,false
    end

    -- Focus on players
    local players = battleCamera.getCamerasPlayers(1)
    local playerCount = #players

    local sumX = 0
    local sumY = 0

    for _,p in ipairs(players) do
        sumX = sumX + (p.x + p.width*0.5 + 128*p.direction)
        sumY = sumY + (p.y + p.height - 96)
    end

    return sumX/playerCount,sumY/playerCount,camera.y - lakituImage.height*0.5,true
end


local stateFuncs = {}

stateFuncs[battleStart.STATE.FLY_IN] = function()
    if not battleStart.lakituActive then
        battleStart.lakituGoalX,battleStart.lakituGoalY,battleStart.lakituStartY,battleStart.lakituScene = getLakituGoal()

        if battleStart.lakituGoalX ~= nil then
            battleStart.lakituStartX = battleStart.lakituGoalX + 96
            --battleStart.lakituStartY = -lakituImage.height*0.5

            battleStart.lakituX = battleStart.lakituStartX
            battleStart.lakituY = battleStart.lakituStartY

            battleStart.lakituSection = Section.getIdxFromCoords(battleStart.lakituX,battleStart.lakituY)

            battleStart.lakituFrame = 0

            battleStart.lakituActive = true
			SFX.play("level intro.mp3")
        end
    else
        battleStart.timer = battleStart.timer + 1

        battleStart.lakituX = easing.outSine(battleStart.timer,battleStart.lakituStartX,battleStart.lakituGoalX - battleStart.lakituStartX,battleStart.lakituEnterTime)
        battleStart.lakituY = easing.outCirc(battleStart.timer,battleStart.lakituStartY,battleStart.lakituGoalY - battleStart.lakituStartY,battleStart.lakituEnterTime)

        if battleStart.timer >= battleStart.lakituEnterTime then
            battleStart.state = battleStart.STATE.WAIT
            battleStart.timer = 0
        end
    end
end


stateFuncs[battleStart.STATE.WAIT] = function()
    battleStart.timer = battleStart.timer + 1

    if battleStart.timer >= battleStart.waitTime then
        battleStart.state = battleStart.STATE.READY
        battleStart.timer = 0
    end
end


local function notReadyToContinue()
    for _,user in ipairs(onlinePlay.getUsers()) do
        if user.playerIdx ~= onlinePlay.hostPlayerIdx and onlinePlay.isConnected(user.playerIdx) and not readyPlayerMap[user.playerIdx] then
            return true
        end
    end

    return false
end

local function setStatusMessage(newMessage)
    if statusMessage ~= newMessage then
        if newMessage ~= nil then
            local text = textFiles.levelStart.statuses[newMessage].. textFiles.levelStart.statusEllipses

            statusMessageLayout = textplus.layout(text,nil,{font = battleStart.statusFont,xscale = battleStart.statusScale,yscale = battleStart.statusScale})
            statusStartTime = onlinePlay.localTime
        end

        statusMessage = newMessage
    end
end


stateFuncs[battleStart.STATE.READY] = function()
    if onlinePlay.isReconnecting then
        return
    end

    if onlinePlay.currentMode == onlinePlay.MODE_HOST then
        if notReadyToContinue() then
            return
        end

        readyCommand:send(0)
    elseif onlinePlay.currentMode == onlinePlay.MODE_CLIENT then
        if not sentReadyMessage then
            readyCommand:send(0)
            sentReadyMessage = true
        end

        if not hostIsReady then
            return
        end
    end

    if battleStart.lakituActive then
        battleStart.state = battleStart.STATE.COUNTDOWN
    else
        battleStart.state = battleStart.STATE.INACTIVE
    end

    battleStart.timer = 0

    bannedCharacters.transform()
end

stateFuncs[battleStart.STATE.COUNTDOWN] = function()
    battleStart.timer = battleStart.timer - 1

    if battleStart.timer <= 0 then
        battleStart.lakituFrame = battleStart.lakituFrame + 1

        if battleStart.lakituFrame >= (lakituFrames - 1) then
            battleStart.state = battleStart.STATE.FINISHED
            battleStart.timer = 0

            battleStart.linkFrametrapFixTimer = 48

            Misc.unpause()

            SFX.play(countdownLastSound)
        else
            battleStart.timer = battleStart.countdownSpeed

            SFX.play(countdownStepSound)
        end

        --battleStart.state = battleStart.STATE.COUNTDOWN
        --battleStart.timer = 0
    end
end


stateFuncs[battleStart.STATE.FINISHED] = function()
    battleStart.backgroundFade = math.max(0,battleStart.backgroundFade - 1/battleStart.finishedTime)
    battleHUD.opacity = math.min(1,battleHUD.opacity + 1/battleStart.finishedTime)

    if battleStart.backgroundFade <= 0 and battleHUD.opacity >= 1 then
        battleStart.state = battleStart.STATE.FLY_OFF
        battleStart.timer = 0

        if not battleGeneral.musicMuted() then
            Audio.ReleaseStream(-1)
        end
    end
end


local function lakituIsFinished()
    if battleStart.lakituScene then
        return (battleStart.lakituY <= camera.y - lakituImage.height*0.5)
    else
        return (battleStart.lakituY <= -lakituImage.height*0.5)
    end
end

stateFuncs[battleStart.STATE.FLY_OFF] = function()
    -- Lakitu flies off
    local speedX = math.min(2,battleStart.timer*0.1)
    local speedY = -math.min(12,battleStart.timer*0.15)

    battleStart.lakituX = battleStart.lakituX + speedX
    battleStart.lakituY = battleStart.lakituY + speedY

    battleStart.timer = battleStart.timer + 1

    -- Finish up
    if lakituIsFinished() then
        battleStart.state = battleStart.STATE.INACTIVE
        battleStart.timer = 0

        battleStart.lakituActive = false
    end
end



function battleStart.onInitAPI()
    registerEvent(battleStart,"onStart")
    registerEvent(battleStart,"onInputUpdate")
    registerEvent(battleStart,"onTick")
    registerEvent(battleStart,"onTickEnd")
    registerEvent(battleStart,"onCameraDraw")

    battleGeneral = require("scripts/battleGeneral")
    battleCamera = require("scripts/battleCamera")
    battleHUD = require("scripts/battleHUD")
    battleMenu = require("scripts/battleMenu")

    onlinePlay = require("scripts/onlinePlay")

    bannedCharacters = require("scripts/bannedCharacters")

    battleStart.initMenus()


    readyCommand = onlinePlay.createCommand("battle_start_ready",onlinePlay.IMPORTANCE_MAJOR)

    function readyCommand.onReceive(sourcePlayerIdx)
        if onlinePlay.currentMode == onlinePlay.MODE_HOST then
            readyPlayerMap[sourcePlayerIdx] = true
        elseif sourcePlayerIdx == onlinePlay.hostPlayerIdx then
            hostIsReady = true 
        end
    end

    function onlinePlay.onReconnect(playerIdx)
        if not onlinePlay.isReconnecting then -- all finished!
            battleStart.unresponsiveTimer = 0
        end
    end
end


function battleStart.onStart()
    if battleGeneral.mode >= 0 and not battleStart.lakituDisabledDebug and (battleGeneral.gameData.playerCount > 1 or not Misc.inEditor()) then
        battleStart.state = battleStart.STATE.QUEUED
        battleStart.timer = 0
        battleStart.backgroundFade = 1

        battleStart.fadeIn = 1

        battleHUD.opacity = 0

        Audio.SeizeStream(-1)
        Audio.MusicStop()
    elseif onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        battleStart.state = battleStart.STATE.READY
        battleStart.timer = 0
    end

    --onlinePlay.isReconnecting = true
end


function battleStart.onInputUpdate()
    local func = stateFuncs[battleStart.state]

    if func ~= nil then
        func()
    end


    -- Handle unresponsive menu
    if battleStart.state == battleStart.STATE.READY and onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        battleStart.unresponsiveTimer = battleStart.unresponsiveTimer + 1
    else
        battleStart.unresponsiveTimer = 0
    end

    if battleStart.unresponsiveTimer >= battleStart.unresponsiveWarningTime then
        if not battleStart.warningMenu.isOpen then
            battleStart.warningMenu:open({},1,Player(onlinePlay.playerIdx),false,true)
        end
    else
        if battleStart.warningMenu.isOpen then
            battleStart.warningMenu:close()
        end
    end

    -- Reconnecting status text
    if onlinePlay.isReconnecting then
        if not onlinePlay.hasReconnected then
            setStatusMessage("reconnecting")
        else
            setStatusMessage("waiting")
        end
    elseif battleStart.state == battleStart.STATE.READY and onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
        setStatusMessage("waiting")
    else
        setStatusMessage(nil)
    end

    -- Lakitu's floating
    if battleStart.lakituActive then
        battleStart.lakituFloatOffset = math.sin(battleStart.lakituFloatTimer/8)*4
        battleStart.lakituFloatTimer = battleStart.lakituFloatTimer + 1
    end

    -- Disable controls at start
    if battleStart.state == battleStart.STATE.QUEUED then
        for _,p in ipairs(Player.get()) do
            for key,_ in pairs(p.keys) do
                p.keys[key] = false
            end
        end
    end


    battleStart.fadeIn = math.max(0,battleStart.fadeIn - 1/12)
end

function battleStart.onTick()
    if battleStart.linkFrametrapFixTimer > 0 then
        battleStart.linkFrametrapFixTimer = math.max(0,battleStart.linkFrametrapFixTimer - 1)

        for _,p in ipairs(Player.get()) do
            if p.character == CHARACTER_LINK then
                p:mem(0x172,FIELD_BOOL,false)
            end
        end
    end
end

function battleStart.onTickEnd()
    if battleStart.state == battleStart.STATE.QUEUED then
        battleStart.state = battleStart.STATE.FLY_IN
        Misc.pause()
    end
end

function battleStart.onCameraDraw(camIdx)
    local cam = Camera(camIdx)

    -- Background fade
    local fadePriority = -0.4

    if battleStart.backgroundFade > 0 then
        Graphics.drawBox{
            color = Color.black.. 0.5*battleStart.backgroundFade,
            priority = fadePriority,

            x = 0,y = 0,width = cam.width,height = cam.height,
        }
    
        for _,p in ipairs(battleCamera.getCamerasPlayers(camIdx)) do
            p:render{
                color = Color.white.. math.min(1,battleStart.backgroundFade*2),
                priority = fadePriority + 0.02,
                ignorestate = true,
            }
        end
    end

    -- Lakitu
    if battleStart.lakituActive then
        local width = lakituImage.width
        local height = lakituImage.height/lakituFrames

        local x = battleStart.lakituX - width*0.5
        local y = battleStart.lakituY - height*0.5 + battleStart.lakituFloatOffset

        if battleStart.lakituScene then
            Graphics.drawImageToSceneWP(lakituImage,x,y,0,battleStart.lakituFrame*height,width,height,fadePriority + 0.01)
        else
            Graphics.drawImageWP(lakituImage,x - cam.renderX,y - cam.renderY,0,battleStart.lakituFrame*height,width,height,2)
        end
    end


    -- Status message
    if statusMessage ~= nil then
        local screenWidth,screenHeight = battleGeneral.getScreenSize()

        local boxOpacity = 1--(1 - battleStart.backgroundFade)
        local priority = 8

        -- Time layout
        --[[local timeValue = math.floor(onlinePlay.localTime - statusStartTime)
        local timeText = textFiles.funcs.replace(textFiles.levelStart.statusTimer,{TIME = timeValue})
        local timeLayout = textplus.layout(timeText,nil,{font = battleStart.statusFont,xscale = battleStart.statusScale,yscale = battleStart.statusScale})]]

        -- Calculate size and position
        local mainWidth = statusMessageLayout.width
        local mainHeight = statusMessageLayout.height

        local statusTextLimit = utf8.len(textFiles.levelStart.statuses[statusMessage]) + math.floor(lunatime.drawtick()/32)%(utf8.len(textFiles.levelStart.statusEllipses) + 1)

        local totalWidth = mainWidth + battleStart.statusBoxMarginX*boxOpacity*2
        local totalHeight = mainHeight + battleStart.statusBoxMarginY*boxOpacity*2

        local totalX = battleStart.statusGap
        local totalY = screenHeight - battleStart.statusGap - totalHeight
        
        local mainX = totalX + battleStart.statusBoxMarginX*boxOpacity
        local mainY = totalY + battleStart.statusBoxMarginY*boxOpacity

        -- Draw box
        if boxOpacity > 0 then
            battleMenu.drawSegmentedBox{
                texture = battleStart.statusBoxImage,priority = priority,
                x = totalX,y = totalY,width = totalWidth,height = totalHeight,
                color = Color.white.. boxOpacity,
            }
        end

        -- Draw text
        textplus.render{
            layout = statusMessageLayout,priority = priority,
            x = mainX,y = mainY + (mainHeight - statusMessageLayout.height)*0.5,
            limit = statusTextLimit,
        }

        --[[textplus.render{
            layout = timeLayout,priority = priority,
            x = mainX + mainWidth - timeLayout.width,y = mainY + (mainHeight - timeLayout.height)*0.5,
        }]]
    end

    -- Fade in
    if battleStart.fadeIn > 0 then
        Graphics.drawBox{
            color = Color.black.. battleStart.fadeIn,
            priority = 10,
            x = 0,
            y = 0,
            width = cam.width,
            height = cam.height,
        }
    end
end


-- Unresponsive warning
function battleStart.initMenus()
    battleStart.warningMenu = battleMenu.createMenu{
        format = {hasBackground = true,hasBox = true,elementGapY = 16},
        optionFormat = {hasBox = false,textScale = 2},
        textFormat = {hasBox = false,textScale = 2,textMaxWidth = 512},
    }
    battleStart.warningMenu.openFunc = function(menu)
        local text = textFiles.levelStart.warning

        -- Main text
        if onlinePlay.currentMode == onlinePlay.MODE_CLIENT then
            if onlinePlay.hasReconnected then
                menu:addText{text = text.client.clientUnresponsive}
            else
                menu:addText{text = text.client.hostUnresponsive}
            end
        else
            menu:addText{text = text.host.unresponsive}
        end

        -- Options
        menu:addOption{text = text.wait,runFunction = function(option)
            battleStart.unresponsiveTimer = 0
            menu:close()
        end}

        --[[if onlinePlay.currentMode == onlinePlay.MODE_HOST then
            menu:addOption{text = text.disconnectOthers,runFunction = function(option)
                for playerIdx = 1,battleGeneral.gameData.playerCount do
                    if playerIdx ~= onlinePlay.playerIdx and GameData.onlinePlay.reconnectingMap[playerIdx] and not readyPlayerMap[playerIdx] then
                        onlinePlay.onDisconnect(playerIdx)

                        GameData.onlinePlay.reconnectingMap[playerIdx] = nil
                        GameData.onlinePlay.userData[playerIdx] = nil
                    end
                end

                battleStart.unresponsiveTimer = 0
                menu:close()
            end}
        end]]

        menu:addOption{text = text.disconnectSelf,runFunction = function(option)
            onlinePlay.disconnect()

            if Level.filename() ~= battleGeneral.hubLevelFilename then
                Level.load(battleGeneral.hubLevelFilename)
                Misc.unpause()
            end
        end}
    end
end


return battleStart