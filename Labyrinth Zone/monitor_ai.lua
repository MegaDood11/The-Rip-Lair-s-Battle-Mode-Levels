--[[

	Written by MrDoubleA
	Please give credit!

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local playerManager = require("playerManager")


local monitor = {}



function monitor.onInitAPI()
    registerEvent(monitor,"onNPCKill")
    registerEvent(monitor,"onPostNPCHarm")

    registerEvent(monitor,"onTick","updateScreens")
    registerEvent(monitor,"onDraw","drawScreens")

    registerEvent(monitor,"onTick","updateShoes")
    registerEvent(monitor,"onDraw","drawShoes")

    registerEvent(monitor,"onTick","onTickShields")
    registerEvent(monitor,"onTickEnd","onTickEndShields")
    registerEvent(monitor,"onDraw","onDrawShields")
    registerEvent(monitor,"onPlayerHarm")
end


-- Stuff for the actual NPC's
do
    -- Settings shared across all of the NPC's because there's a lot of NPC's in this one and they're all really similar to each other
    monitor.sharedSettings = {
        gfxwidth = 32,
        gfxheight = 40,

        gfxoffsetx = 0,
        gfxoffsety = 2,
        
        width = 32,
        height = 40,
        
        frames = 3,
        framestyle = 0,
        framespeed = 24,
        
        speed = 1,
        
        npcblock = false,
        npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
        playerblock = false,
        playerblocktop = false, --Also handles other NPCs walking atop this NPC.

        nohurt = true,
        nogravity = false,
        noblockcollision = false,
        nofireball = true,
        noiceball = true,
        noyoshi = true,
        nowaterphysics = false,
        
        ignorethrownnpcs = false,
        
        jumphurt = false,
        spinjumpsafe = false,
        harmlessgrab = false,
        harmlessthrown = false,
        

        lightradius = 64,
        lightbrightness = 0.75,
        lightoffsetx = 0,
        lightoffsety = 0,
        lightcolor = Color.white,
        

        -- Animation settings
        staticFrames = 2,
        staticTime = 7,

        -- Other stuff
        breakSound = SFX.open(Misc.resolveSoundFile("sonic-break")),

        -- The NPC it turns into when broken. If nil, defaults to the first broken monitor NPC ID.
        brokenNPCID = nil,
    }




    monitor.idList = {}
    monitor.idMap  = {}

    monitor.effectFunctionMap = {}

    function monitor.register(npcID,effectFunction)
        npcManager.registerEvent(npcID, monitor, "onTickNPC")
        npcManager.registerEvent(npcID, monitor, "onTickEndNPC")
        
        table.insert(monitor.idList,npcID)
        monitor.idMap[npcID] = npcID
        monitor.effectFunctionMap[npcID] = effectFunction
    end


    monitor.brokenIDList = {}
    monitor.brokenIDMap  = {}

    function monitor.registerBroken(npcID)
        table.insert(monitor.brokenIDList,npcID)
        monitor.brokenIDMap[npcID] = true
    end


    local function initialise(v,data,config)
        if data.initialised then return end

        data.initialised = true
            
        data.bumped = false

        data.animationTimer = 0


        v.noblockcollision = true
    end

    local function updateAnimationFrame(v,data,config)
        local staticFrames = config.staticFrames
        local normalFrames = config.frames-staticFrames

        local normalTime = normalFrames*config.framespeed
        local staticTime = config.staticTime


        local timer = data.animationTimer%(normalTime+staticTime)

        local frame = 0

        if timer < normalTime then
            frame = math.floor(timer/config.framespeed)
        else
            frame = math.floor((timer-normalTime)/(staticTime/staticFrames))+normalFrames
        end

        v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})


        data.animationTimer = data.animationTimer + 1
    end

    function monitor.onTickNPC(v)
        if Defines.levelFreeze then return end
        
        local data = v.data
        
        if v.despawnTimer <= 0 then
            data.initialised = false
            return
        end
        

        local config = NPC.config[v.id]

        initialise(v,data,config)

        if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
        or v:mem(0x136, FIELD_BOOL)        --Thrown
        or v:mem(0x138, FIELD_WORD) > 0    --Contained within
        then return end
        
        
        if not data.bumped then
            -- Gravity is cancelled if not bumped
            local gravity = Defines.npc_grav
            if config.nogravity then
                gravity = 0
            elseif v.underwater then
                gravity = gravity*0.2
            end

            if v.spawnId > 0 then
                v.speedX = (v.spawnX-v.x)
                v.speedY = (v.spawnY-v.y) - gravity
            else
                v.speedX = 0
                v.speedY = -gravity
            end

            
            npcutils.applyLayerMovement(v)


            -- Check to see if it's been bumped
            local npcCol = Colliders.getSpeedHitbox(v)

            for _,p in ipairs(Player.get()) do
                if p.deathTimer == 0 and p.forcedState == FORCEDSTATE_NONE and p.speedY < 0 and (p.y-p.speedY >= v.y+v.height-v.speedY) then
                    local playerCol = Colliders.getSpeedHitbox(p)

                    if npcCol ~= nil and playerCol ~= nil and playerCol:collide(npcCol) then
                        data.bumped = true

                        v.speedY = -3

                        break
                    end
                end
            end
        else
            if v.noblockcollision then -- if noblockcollision is still active, check to see if it can be cancelled
                v.noblockcollision = #Colliders.getColliding{a = v,b = Block.SOLID.. Block.PLAYER,btype = Colliders.BLOCK} > 0
            end
        end
    end

    function monitor.onTickEndNPC(v)
        if Defines.levelFreeze then return end
        
        local data = v.data
        
        if v.despawnTimer <= 0 then
            return
        end
        

        local config = NPC.config[v.id]

        initialise(v,data,config)

        
        updateAnimationFrame(v,data,config)
    end



    function monitor.onPostNPCHarm(v,reason,culprit)
        if monitor.idMap[v.id] then
            local data = v.data

            if type(culprit) == "Player" then
                data.culpritPlayer = culprit
            elseif type(culprit) == "NPC" then
                if culprit:mem(0x12C,FIELD_WORD) > 0 then
                    data.culpritPlayer = Player(culprit:mem(0x12C,FIELD_WORD))
                elseif culprit:mem(0x132,FIELD_WORD) > 0 then
                    data.culpritPlayer = Player(culprit:mem(0x132,FIELD_WORD))
                end
            end
        end
    end

    function monitor.onNPCKill(eventObj,v,reason)
        if not monitor.idMap[v.id] or reason == HARM_TYPE_OFFSCREEN then return end

        local config = NPC.config[v.id]
        local data = v.data

        if config.breakSound ~= nil then
            SFX.play(config.breakSound)
        end

        if config.screenImage ~= nil then
            monitor.createScreen(v.id,v.x+(v.width*0.5),v.y+(v.height*0.5),config.screenImage,config.effectSound,monitor.effectFunctionMap[v.id],data.culpritPlayer)
        end
		
		Routine.run(function()
		Routine.wait(1.25)
		Effect.spawn(10, v.x, v.y - v.height * 2.75)
		NPC.spawn(909, v.x, v.y - v.height * 2.75)
		end)

        local id = config.brokenNPCID or monitor.brokenIDList[1]

        if id ~= nil then
            v:transform(id,true,v.spawnId > 0)

            v.noblockcollision = false
            v.speedX = 0 -- thanks redigit

            eventObj.cancelled = true
        end
    end
end

-- Stuff for the screens that pop out when you hit a monitor
do
    monitor.activeScreens = {}

    function monitor.createScreen(id,x,y,image,effectSound,effectFunction,playerObj)
        local screen = {}

        screen.npcID = id

        screen.x = x
        screen.y = y

        screen.image = image
        screen.effectFunction = effectFunction
        screen.effectSound = effectSound

        screen.playerObj = playerObj


        screen.opacity = 1
        screen.speedY = -4

        screen.timer = 0


        table.insert(monitor.activeScreens,screen)

        return screen
    end


    function monitor.updateScreens()
        for k = #monitor.activeScreens, 1, -1 do
            local screen = monitor.activeScreens[k]

            if screen.speedY ~= 0 then
                screen.speedY = math.min(0,screen.speedY + 0.08)

                screen.y = screen.y + screen.speedY
            elseif screen.opacity > 0 then
                screen.timer = screen.timer + 1

                if screen.timer == 4 then
                    if screen.effectFunction ~= nil then
                        local playerObj = screen.playerObj
                        if playerObj ~= nil and not playerObj.isValid then
                            playerObj = nil
                        end

                        screen.effectFunction(playerObj,screen.npcID,NPC.config[screen.npcID],screen)
                    end
                    if screen.effectSound ~= nil then
                        SFX.play(screen.effectSound)
                    end
                elseif screen.timer >= 24 then
                    screen.opacity = screen.opacity - 0.1
                end
            else
                table.remove(monitor.activeScreens,k)
            end
        end
    end

    function monitor.drawScreens()
        for _,screen in ipairs(monitor.activeScreens) do
            Graphics.drawImageToSceneWP(screen.image,screen.x-(screen.image.width*0.5),screen.y-(screen.image.height*0.5),screen.opacity,-5)
        end
    end
end

-- Stuff for the speed shoes effect
do
    monitor.speedShoesDuration = lunatime.toTicks(12)

    monitor.speedShoesTimer = 0

    monitor.speedShoesSpeedIncrease = 2


    function monitor.startSpeedShoes(duration)
        if monitor.speedShoesTimer == 0 then
            Defines.player_walkspeed = Defines.player_walkspeed * monitor.speedShoesSpeedIncrease
            Defines.player_runspeed  = Defines.player_runspeed  * monitor.speedShoesSpeedIncrease
        end

        monitor.speedShoesTimer = duration or monitor.speedShoesDuration
    end
    function monitor.stopSpeedShoes()
        if monitor.speedShoesTimer ~= 0 then
            Defines.player_walkspeed = Defines.player_walkspeed / monitor.speedShoesSpeedIncrease
            Defines.player_runspeed  = Defines.player_runspeed  / monitor.speedShoesSpeedIncrease
        end

        monitor.speedShoesTimer = 0
    end


    monitor.afterimages = {}

    function monitor.createAfterimage(p)
        local obj = {
            player = p,


            x = p.x,
            y = p.y,

            character = p.character,
            powerup = p.powerup,

            direction = p.direction,
            frame = p.frame,

            mount = p.mount,


            opacity = 0.6,
        }

        table.insert(monitor.afterimages,obj)

        return obj
    end

    function monitor.updateShoes()
        -- Update afterimages
        for k=#monitor.afterimages,1,-1 do
            local obj = monitor.afterimages[k]

            obj.opacity = obj.opacity - 0.1

            if obj.opacity <= 0 or not obj.player.isValid then
                table.remove(monitor.afterimages,k)
            end
        end


        -- Update effect
        if monitor.speedShoesTimer ~= 0 then
            if monitor.speedShoesTimer > 0 then
                if monitor.speedShoesTimer == 1 then
                    monitor.stopSpeedShoes()
                    
                    for _,p in ipairs(Player.get()) do
                        p:mem(0x140,FIELD_WORD,50)
                    end
                    SFX.play(5)
                end

                monitor.speedShoesTimer = math.max(0,monitor.speedShoesTimer - 1)
            end

            for _,p in ipairs(Player.get()) do
                monitor.createAfterimage(p)
            end
        end
    end

    function monitor.drawShoes()
        for _,obj in ipairs(monitor.afterimages) do
            local p = obj.player

            if p.isValid then
                p:render{
                    x = obj.x,
                    y = obj.y,
        
                    character = obj.character,
                    powerup = obj.powerup,
        
                    direction = obj.direction,
                    frame = obj.frame,
        
                    mount = obj.mount,
        
        
                    color = Color.white.. obj.opacity,

                    priority = (p.forcedState == FORCEDSTATE_PIPE and -75.05) or -25.05,
                }
            end
        end
    end
end

-- Stuff for shields
do
    local playerData = {}
    function monitor.getPlayerData(p)
        playerData[p] = playerData[p] or {}
        return playerData[p]
    end


    monitor.shieldConfig = {}

    function monitor.registerShield(npcID,onTick,onTickEnd,onDraw,isInvincibleTo)
        local npcConfig = NPC.config[npcID]
        local name = npcConfig.shieldName

        if name == nil then
            return
        end

        assert(monitor.shieldConfig[name] == nil,"Shield name '".. name.. "' is already used.")

        local config = {}

        config.npcConfig = npcConfig


        config.getSound = npcConfig.shieldGetSound
        config.lostSound = npcConfig.shieldLostSound
        config.useSound = npcConfig.shieldUseSound

        -- Load each layer
        config.images = {}
        config.frames = {}
        config.frameDelays = {}

        local i = 1
        while (true) do
            config.images[i] = npcConfig["shieldImage".. i]
            config.frames[i] = npcConfig["shieldFrames".. i]
            config.frameDelays[i] = npcConfig["shieldFrameDelay".. i]

            if config.images[i] == nil or config.frames[i] == nil or config.frameDelays[i] == nil then
                break
            else
                i = i + 1
            end
        end


        config.onTick = onTick
        config.onTickEnd = onTickEnd
        config.onDraw = onDraw
        config.isInvincibleTo = isInvincibleTo


        monitor.shieldConfig[name] = config
    end



    function monitor.setShield(p,shieldType,silent)
        local data = monitor.getPlayerData(p)

        if shieldType ~= nil then
            local config = monitor.shieldConfig[shieldType]

            if config.getSound ~= nil then
                SFX.play(config.getSound)
            end
        elseif data.currentShield ~= nil then
            local config = monitor.shieldConfig[data.currentShield]

            if config.lostSound ~= nil then
                SFX.play(config.lostSound)
            end
        end

        data.currentShield = shieldType
        data.behaviour = {}

        data.shieldSprites = {}

        data.animationTimer = 0
        data.priorityOffset = {}
    end


    local invisibleStates = table.map{FORCEDSTATE_INVISIBLE,FORCEDSTATE_SWALLOWED}
    local function canDrawShield(p)
        return (
            not invisibleStates[p.forcedState]
            and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)
            and not p.isMega
        )
    end

    local function getPriority(p)
        if p.forcedState == FORCEDSTATE_PIPE then
            return -75
        else
            return -25
        end
    end

    function monitor.drawShieldLayer(p,layerIndex,frame)
        if not canDrawShield(p) then return end

        local data = monitor.getPlayerData(p)
        local config = monitor.shieldConfig[data.currentShield]

        frame = frame or math.floor(data.animationTimer/config.frameDelays[layerIndex])%config.frames[layerIndex]


        if data.shieldSprites[layerIndex] == nil then
            data.shieldSprites[layerIndex] = Sprite{texture = config.images[layerIndex],frames = config.frames[layerIndex],pivot = Sprite.align.CENTRE}
        end

        local sprite = data.shieldSprites[layerIndex]

        sprite.x = p.x+(p.width *0.5)
        sprite.y = p.y+(p.height*0.5)

        sprite:draw{frame = frame+1,priority = getPriority(p) + (data.priorityOffset[layerIndex] or 0.5),sceneCoords = true}
    end


    function monitor.canRestoreJumpAbility(p)
        return (
            p:isOnGround()
            or p.climbing
            or p:mem(0x06,FIELD_WORD) > 0 -- quicksand
            or p:mem(0x36,FIELD_BOOL)     -- underwater
            or p:mem(0x44,FIELD_BOOL)     -- on a rainbow shell
        )
    end

    function monitor.canUseJumpAbility(p)
        return (
            p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)

            and not p:isOnGround()

            and not p.climbing
            and not p.isMega
            and p.mount ~= MOUNT_CLOWNCAR

            and not p:mem(0x00,FIELD_BOOL)  -- leaf toad's double jump
            and p:mem(0x06,FIELD_WORD) == 0 -- quicksand
            and not p:mem(0x0C,FIELD_BOOL)  -- fairy
            and p:mem(0x1C,FIELD_WORD) == 0 -- peach's hover timer
            and not p:mem(0x36,FIELD_BOOL)  -- underwater
            and not p:mem(0x3C,FIELD_BOOL)  -- sliding down a slope
            and not p:mem(0x44,FIELD_BOOL)  -- on a rainbow shell
            and not p:mem(0x4A,FIELD_BOOL)  -- statue
            and not p:mem(0x5C,FIELD_BOOL)  -- purple yoshi ground pounding
            and not p:mem(0x16E,FIELD_BOOL) -- flying with leaf
        )
    end


    local function npcHarmfulFilter(v)
        local config = NPC.config[v.id]

        return (
            Colliders.FILTER_COL_NPC_DEF(v)
            and v.despawnTimer > 0
            and not config.nohurt
            and not config.isinteractable
        )
    end

    local colBox = Colliders.Box(0,0,0,0)
    local function getHarmCulprit(p)
        local col = Colliders.getSpeedHitbox(p)

        colBox.x = math.min(p.x,p.x+p.speedX)
        colBox.y = math.min(p.y,p.y+p.speedY)
        colBox.width  = math.max(p.x+p.width ,p.x+p.width +p.speedX)-colBox.x
        colBox.height = math.max(p.y+p.height,p.y+p.height+p.speedY)-colBox.y


        local npcs   = Colliders.getColliding{a = colBox,btype = Colliders.NPC  ,filter = npcHarmfulFilter  }
        local blocks = Colliders.getColliding{a = colBox,btype = Colliders.BLOCK,b = Block.HURT.. Block.LAVA}

        return (npcs[1] or blocks[1])
    end
    

    function monitor.onPlayerHarm(eventObj,p)
        local data = monitor.getPlayerData(p)

        if data.currentShield == nil or p:mem(0x140,FIELD_WORD) ~= 0 then
            return
        end

        local config = monitor.shieldConfig[data.currentShield]

        -- Check for environmental attacks
        if config.isInvincibleTo ~= nil then
            local culprit = getHarmCulprit(p)

            if culprit ~= nil and config.isInvincibleTo(p,culprit) then
                eventObj.cancelled = true
                return
            end
        end

        -- Lose shield
        monitor.setShield(p,nil)

        p:mem(0x140,FIELD_WORD,150)

        if playerManager.getBaseID(p.character) == CHARACTER_LINK then
            -- Activate link's hit animation
            p.speedX = -3 * p.direction
            p.speedY = -7.01

            p:mem(0x118,FIELD_FLOAT,-10) -- animation timer (-10 means hurt)

            p:mem(0x176,FIELD_WORD,0) -- standing on NPC
            p:mem(0x160,FIELD_WORD,30) -- fireball cooldown
            p:mem(0x14,FIELD_WORD,0) -- slash timer
        end

        eventObj.cancelled = true
    end


    local function callEvent(eventName)
        for _,p in ipairs(Player.get()) do
            local data = monitor.getPlayerData(p)

            if data.currentShield ~= nil then
                local config = monitor.shieldConfig[data.currentShield]

                if eventName == "onTick" then
                    data.animationTimer = data.animationTimer + 1
                end

                if config[eventName] ~= nil then
                    config[eventName](p,data.behaviour,data,config)
                end
            end
        end
    end

    function monitor.onTickShields()
        callEvent("onTick")
    end
    function monitor.onTickEndShields()
        callEvent("onTickEnd")
    end
    function monitor.onDrawShields()
        callEvent("onDraw")
    end
end



function monitor.addCoins(amount)
    mem(COINS_ADDR,FIELD_WORD,mem(COINS_ADDR,FIELD_WORD)+amount)

    if mem(COINS_ADDR,FIELD_WORD) >= 100 then
        if mem(LIVES_ADDR,FIELD_FLOAT) < 99 then
            mem(LIVES_ADDR,FIELD_FLOAT,mem(LIVES_ADDR,FIELD_FLOAT)+math.floor(mem(COINS_ADDR,FIELD_WORD)/100))
            SFX.play(15)

            mem(COINS_ADDR,FIELD_WORD,mem(COINS_ADDR,FIELD_WORD)%100)
        else
            mem(COINS_ADDR,FIELD_WORD,99)
        end
    end
end


return monitor