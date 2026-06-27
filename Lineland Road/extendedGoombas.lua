--[[

    Extended Goombas 
    Made by DeviousQuacks23
    Please give credit...

    Based off of the galoombas written by MrDoubleA, so credits to him.
    This was also inspired by extendedKoopas.lua (also written by MDA)

    SMB1 Goombrat sprites by SuperSledgeBro
    SMB1 Galoomba and Goombud sprites by Evan F, tweaked by me

    SMB3 Goombrat sprites by Prismkick
    SMB3 Galoomba sprites by DogeMayo
    SMB3 Goombud sprites by MarShadowSlime, modified by me

    SMW Goomba and Goombrat sprites by Stranimations, palettes tweaked by me
]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

local extendedGoombas = {}

extendedGoombas.sharedSettings = {
    npcblock = false,
    npcblocktop = false,
    playerblock = false,
    playerblocktop = false, 

    nohurt = false,
    nogravity = false,
    noblockcollision = false,
    nofireball = false,
    noiceball = false,
    noyoshi = false,
    nowaterphysics = false,
	
    harmlessgrab = false,
    harmlessthrown = false,

    luahandlesspeed = true,
    speed = 1.2,

    jumphurt = false,
    spinjumpsafe = false,

    -- Custom settings

    isGaloomba = false,

    isStunned = false,

    kickedSpeedX = 5,
    kickedSpeedY = -2.5,

    recoverTime = 400,
    shakeTime = 50,

    recoverHopSpeed = -5,

    isWinged = false,

    preHopTime = 60,
    hopCount = 5,
    hopSpeedSmall = -3,
    hopSpeedBig = -7,
    hopTurnsAround = false,

    wingFrames = 2,
    wingFramespeed = 4,
    animateFastOnFinalJump = false,

    wingStompSFX = 2,

    normalID = 1,
    stunnedID = 1,
    recoverID = 1,
	
    chasePlayer = false,
    facePlayerTime = 65,
}

extendedGoombas.idList = {}
extendedGoombas.idMap  = {}

function extendedGoombas.register(npcID)
    npcManager.registerEvent(npcID, extendedGoombas, "onTickEndNPC")

    table.insert(extendedGoombas.idList,npcID)
    extendedGoombas.idMap[npcID] = true
end

function extendedGoombas.onInitAPI()
    registerEvent(extendedGoombas,"onNPCHarm")
end

local function initialise(v,data,config)
    data.initialized = true

    data.timer = 0
    data.turnTimer = 0
    data.hopCounter = 0

    data.dontWalk = false

    data.animationTimer = 0
    data.wingAnimationTimer = 0
end

local function doStun(v,data,config)
    if config.stunnedID ~= nil then
        v:transform(config.stunnedID)
    end
    config = NPC.config[v.id]

    initialise(v,data,config)

    v.speedX = 0
end

local function kickStunned(v,data,config, culprit)
    if type(culprit) == "Player" then
        if v.x+v.width*0.5 < culprit.x+culprit.width*0.5 then
            v.direction = DIR_LEFT
        else
            v.direction = DIR_RIGHT
        end

        v:mem(0x12E,FIELD_WORD,10)
        v:mem(0x130,FIELD_WORD,culprit.idx)
    end

    v:mem(0x136,FIELD_BOOL,true)

    v.speedX = config.kickedSpeedX * v.direction
    v.speedY = config.kickedSpeedY

    SFX.play(9)
end

local function handleAnimation(v,data,config)
    local direction = v.direction
    local frame = 0

    local shakeTimer = 0

    -- Find frame
    if config.isStunned then
        shakeTimer = (data.timer - (config.recoverTime - config.shakeTime))
    end        

    local frameCount = config.frames / ((config.isWinged and config.wingFrames) or 1)

    frame = math.floor(data.animationTimer / config.framespeed) % frameCount

    if config.isWinged then
        frame = frame + (math.floor(data.wingAnimationTimer / config.wingFramespeed) % config.wingFrames)*frameCount
    end

    -- Advance animation
    if shakeTimer > 0 or data.dontWalk then
        data.animationTimer = data.animationTimer + 2
    else
        data.animationTimer = data.animationTimer + 1
    end

    if config.isWinged then
        if ((data.hopCounter >= config.hopCount) and config.animateFastOnFinalJump) then -- final jump
            data.wingAnimationTimer = data.wingAnimationTimer + 2
        elseif data.hopCounter > 0 then -- hopping
            data.wingAnimationTimer = data.wingAnimationTimer + 1
        else -- walking
            data.wingAnimationTimer = 0
        end
    end

    v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame,direction = direction})
end

function extendedGoombas.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

    local config = NPC.config[v.id]

	if not data.initialized then
		initialise(v,data,config)
	end

    if config.isStunned and v:mem(0x138,FIELD_WORD) == 0 then
        -- Slow it down
        if v:mem(0x12C,FIELD_WORD) == 0 then
            if v.collidesBlockBottom then
                if v.speedX > 0 then
                    v.speedX = math.max(0,v.speedX - 0.35)
                elseif v.speedX < 0 then
                    v.speedX = math.min(0,v.speedX + 0.35)
                end
            else
                if v.speedX > 0 then
                    v.speedX = math.max(0,v.speedX - 0.05)
                elseif v.speedX < 0 then
                    v.speedX = math.min(0,v.speedX + 0.05)
                end
            end

            -- Reset timer if .CantHurt > 0
            if v:mem(0x12E,FIELD_WORD) > 0 then
                data.timer = 0
            end
        end

        -- Wake up
        data.timer = data.timer + 1

        if data.timer >= config.recoverTime and v.collidesBlockBottom then
            -- Jump out of player's arms
            if v:mem(0x12C,FIELD_WORD) > 0 then
                local p = Player(v:mem(0x12C,FIELD_WORD))

                p:harm()

                p:mem(0x154,FIELD_WORD,0)
                v:mem(0x12C,FIELD_WORD,0)
            end

            v.speedY = config.recoverHopSpeed
            v.collidesBlockBottom = false

            v:transform(config.recoverID)
            initialise(v,data,config)
            config = NPC.config[v.id]

            data.dontWalk = true

        end
    end


	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
        handleAnimation(v,data,config)
        return
    end

	
    if not config.isStunned then
        if data.dontWalk then
            data.dontWalk = (data.dontWalk and not v.collidesBlockBottom)
        else
            v.speedX = config.speed * v.direction
        end

        -- Hopping
        if config.isWinged and not data.dontWalk and v.collidesBlockBottom then
            data.timer = data.timer + 1

            if data.timer >= config.preHopTime then
                data.hopCounter = data.hopCounter + 1

                if data.hopCounter > config.hopCount then
                    data.timer = 0
                    data.hopCounter = 0

                    if config.hopTurnsAround then
                        v.direction = -v.direction
                    end
                elseif data.hopCounter >= config.hopCount then
                    v.speedY = config.hopSpeedBig
                else
                    v.speedY = config.hopSpeedSmall
                end
            end
        end

        data.turnTimer = data.turnTimer + 1
        if data.turnTimer >= config.facePlayerTime then
            if config.chasePlayer then
                npcutils.faceNearestPlayer(v)
            end
            data.turnTimer = 0
        end
    else
        for _,p in ipairs(Player.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
            if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)
            and (v:mem(0x12E,FIELD_WORD) <= 0 or v:mem(0x130,FIELD_WORD) ~= p.idx)
            then
                kickStunned(v,data,config,p)
            end
        end
    end

    handleAnimation(v,data,config)
end

function extendedGoombas.onNPCHarm(eventObj,v,reason,culprit)
    if not extendedGoombas.idMap[v.id] then return end

    local config = NPC.config[v.id]
    local data = v.data

    if not data.initialized then
		initialise(v,data,config)
	end

    if reason == HARM_TYPE_JUMP then
        if config.isGaloomba or config.isStunned or config.isWinged then
            if (config.isGaloomba and not config.isWinged) then
                doStun(v,data,config)
                SFX.play(9)
            elseif config.isWinged then
                v:transform(config.normalID)
                v.speedY = v.speedY / 4
                SFX.play(config.wingStompSFX)
            elseif config.isStunned then
                kickStunned(v,data,config,culprit)
            end
        
            eventObj.cancelled = true
            return
        end
    elseif reason == HARM_TYPE_FROMBELOW or reason == HARM_TYPE_TAIL then
        if config.isGaloomba or config.isStunned then
            if v:mem(0x26,FIELD_WORD) == 0 then
                if not config.isStunned then
                    doStun(v,data,config)
                else
                    data.timer = 0
                end

                SFX.play(9)

                v.speedY = -5
		v:mem(0x136,FIELD_BOOL,true)

                v:mem(0x26,FIELD_WORD,10) 
            end

            eventObj.cancelled = true
            return
        end
    end
end

onlinePlayNPC.onlineHandlingConfig[extendedGoombas.idMap] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			initialized = data.initialized,
			timer = data.timer,
			hopCounter = data.hopCounter,
			turnTimer = data.turnTimer,
			dontWalk = data.dontWalk,
			animationTimer = data.animationTimer,
			wingAnimationTimer = data.wingAnimationTimer,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.initialized = receivedData.initialized
		data.timer = receivedData.timer
		data.hopCounter = receivedData.hopCounter
		data.turnTimer = receivedData.turnTimer
		data.dontWalk = receivedData.dontWalk
		data.animationTimer = receivedData.animationTimer
		data.wingAnimationTimer = receivedData.wingAnimationTimer
	end,
}

return extendedGoombas