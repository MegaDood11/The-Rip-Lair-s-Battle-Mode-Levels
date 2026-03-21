local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")


local battlePlayer = require("scripts/battlePlayer")
local battleItems = require("scripts/battleItems")
local battlePhanto = require("scripts/battlePhanto")

local onlinePlay = require("scripts/onlinePlay")
local onlinePlayNPC = require("scripts/onlinePlay_npc")
local onlinePlayPlayers = require("scripts/onlinePlay_players")


local bluePhanto = {}


bluePhanto.idList = {}
bluePhanto.idMap = {}


bluePhanto.sharedSettings = {
    id = npcID,

	--Sprite size
	gfxheight = 112,
	gfxwidth = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 16,
	--Frameloop-related
	frames = 3,
	framestyle = 0,
	framespeed = 4, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	homingspeed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	terminalvelocity = -1,


	--Define custom properties below
	awakenoffscreen = false,

	enterawayfromplayer = false,


	chaseacceleration = 0.15,
	chasemaxspeed = 5,


	chargeattackenabled = true,

	chargeradius = 160,
    chargecooldown = 64,

	chargeanticipationtime = 24,
	chargeanticipationspeed = 3,

	chargeadditionaldistance = 48,
	chargeaccelerationtime = 8,
	chargespeed = 15,

	chargedecelerationtime = 24,


	permanentleavingenabled = true,

	leaveradius = 320,
	leavetime = 640,

	chargereduceleavetime = 96,


	flashstartframe = 0,
	flashendframe = 2,

	sleepstartframe = 0,
	sleependframe = 0,

	chasestartframe = 0,
    chaseendframe = 0,

	chargeanticipationstartframe = 0,
	chargeanticipationendframe = 0,

	chargestartframe = 0,
	chargeendframe = 0,

	awakenTime = 32,
	shakeTime = 65,


    awakenSound = Misc.resolveSoundFile("phanto-awaken"),
	shakeSound = Misc.resolveSoundFile("phanto-shake"),
	moveSound = Misc.resolveSoundFile("phanto-move"),

    chargeAnticipationSound = Misc.resolveSoundFile("resources/phanto_charge_anticipation"),
    chargeSound = Misc.resolveSoundFile("resources/phanto_charge"),

    spbSound = Misc.resolveSoundFile("resources/spb"),
    spbSoundEnabled = true,
}


local onlineHandlingConfig = {
	getExtraData = function(v)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		return {
			targetPlayerIdx = (data.targetPlayer ~= nil and data.targetPlayer.idx) or 0,

			state = data.state,
			timer = data.timer,
			startSection = data.startSection,

			stunTimer = data.stunTimer,

			leaving = data.leaving,
			leaveTimer = data.leaveTimer,
			leaveDirection = data.leaveDirection,

			chargeDirection = data.chargeDirection,
			chargeTime = data.chargeTime,
			chargeCooldown = data.chargeCooldown,

			roamTargetPosition = data.roamTargetPosition,

			forceCharge = data.forceCharge,
		}
	end,
	setExtraData = function(v,receivedData)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		if receivedData.targetPlayerIdx > 0 then
			data.targetPlayer = Player(receivedData.targetPlayerIdx)
		else
			data.targetPlayer = nil
		end

		data.state = receivedData.state
		data.timer = receivedData.timer
		data.startSection = receivedData.startSection

		data.stunTimer = receivedData.stunTimer

		data.leaving = receivedData.leaving
		data.leaveTimer = receivedData.leaveTimer
		data.leaveDirection = receivedData.leaveDirection

		data.chargeDirection = receivedData.chargeDirection
		data.chargeTime = receivedData.chargeTime
		data.chargeCooldown = receivedData.chargeCooldown

		data.roamTargetPosition = receivedData.roamTargetPosition

		data.forceCharge = receivedData.forceCharge
	end,
	shouldStealFunc = function(v)
		return false
	end,
}


function bluePhanto.register(npcID)
    npcManager.registerEvent(npcID, bluePhanto, "onTickNPC")
    npcManager.registerEvent(npcID, bluePhanto, "onDrawNPC")

    table.insert(bluePhanto.idList,npcID)
    bluePhanto.idMap[npcID] = true

	onlinePlayNPC.onlineHandlingConfig[npcID] = onlineHandlingConfig
end


local STATE = {
	INACTIVE = 1,
	AWAKEN = 2,
	SHAKE = 3,
	FOLLOW = 4,
	HOSTAGE = 5,
	CHARGE_ANTICIPATION = 6,
	CHARGE_GO = 7,
	CHARGE_STOP = 8,
	ROAM = 9,
}

bluePhanto.STATE = STATE


local shakeSoundCommand = onlinePlayNPC.createNPCCommand("bluePhanto_shakeSound",onlinePlay.IMPORTANCE_MAJOR)

local claimWearCommand = onlinePlay.createCommand("bluePhanto_claimWear",onlinePlay.IMPORTANCE_MAJOR)
local wearCommand = onlinePlay.createCommand("bluePhanto_wear",onlinePlay.IMPORTANCE_MAJOR)


local function phantoTryWear(v,p)
	if not onlinePlayPlayers.ownsPlayer(p) or battlePhanto.isWearingMask(p) or p.idx == v:mem(0x130,FIELD_WORD) then
		return
	end

	if (not battlePhanto.playerWearableForcedStateMap[p.forcedState] and not p.inClearPipe) or p.invincibilityTimer ~= 0 or p.hasStarman or p.isTanookiStatue then
		return
	end

	local data = v.data

	local startX = v.x + v.width*0.5
	local startY = v.y + v.height*0.5

	if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
		if onlinePlayNPC.ownsNPC(v) then
			wearCommand:send(0, onlinePlay.playerIdx,v.id,onlinePlayNPC.getUIDFromNPC(v),startX,startY)
		else
			if not data.hasClaimedWear then
				claimWearCommand:send(onlinePlayNPC.getOwner(v), onlinePlayNPC.getUIDFromNPC(v))
				data.hasClaimedWear = true
			end

			return
		end
	end

	battlePhanto.putOnMask(p,v.id,battlePhanto.PUT_ON_STYLE.FORCED_STATE,startX,startY)
	onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
end


function shakeSoundCommand.onReceive(npc,sourcePlayerIdx, isSPB)
    local config = NPC.config[npc.id]

	if isSPB then
		SFX.play(config.spbSound)
	else
		SFX.play(config.shakeSound)
	end
end

function claimWearCommand.onReceive(sourcePlayerIdx, phantoUID)
	local v = onlinePlayNPC.getNPCFromUID(phantoUID)

	if v == nil or not onlinePlayNPC.ownsNPC(v) or not bluePhanto.idMap[v.id] then
		return
	end

	local config = NPC.config[v.id]

	if not config.wearable then
		return
	end

	local sourcePlayer = Player(sourcePlayerIdx)

	local startX = v.x + v.width*0.5
	local startY = v.y + v.height*0.5

	wearCommand:send(0, sourcePlayerIdx,v.id,phantoUID,startX,startY)

	battlePhanto.putOnMask(sourcePlayer,v.id,battlePhanto.PUT_ON_STYLE.FORCED_STATE,startX,startY)
	onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
end

function wearCommand.onReceive(sourcePlayerIdx, wearerPlayerIdx,npcID,phantoUID,startX,startY)
	local wearerPlayer = Player(wearerPlayerIdx)
	local v = onlinePlayNPC.getNPCFromUID(phantoUID)

	if v ~= nil then
		-- If the NPC exists on our end (it should, be we account for the other
		-- possibility anyway because desyncing would be REALLY bad here),
		-- replace the starting position with where it is on our end
		startX = v.x + v.width*0.5
		startY = v.y + v.height*0.5
	end

	battlePhanto.putOnMask(wearerPlayer,npcID,battlePhanto.PUT_ON_STYLE.FORCED_STATE,startX,startY)

	if v ~= nil then
		onlinePlayNPC.forceKillNPC(v,HARM_TYPE_VANISH)
	end
end


-- like math.min, but it goes by the smallest *absolute* value
local function absMin(...)
    local minValue

    for _,value in ipairs{...} do
        if minValue == nil or math.abs(value) < math.abs(minValue) then
            minValue = value
        end
    end

    return minValue
end

local function approach(current,goal,speed)
	if current > goal then
		return math.max(goal,current - speed)
	elseif current < goal then
		return math.min(goal,current + speed)
	else
		return goal
	end
end


local function targetIsValid(v,p)
	local playerData = battlePlayer.getPlayerData(p)

	if playerData.isDead then
		return false
	end

	if v:mem(0x130,FIELD_WORD) > 0 then
		if p.idx == v:mem(0x130,FIELD_WORD) or battlePlayer.playersAreOnSameTeam(p.idx,v:mem(0x130,FIELD_WORD)) then
			return false
		end
	end

	local config = NPC.config[v.id]

	if config.wearable and battlePhanto.isWearingMask(p) then
		return false
	end

	return true
end

local function targetIsAlreadyChased(v,p)
	for _,phanto in NPC.iterateByFilterMap(bluePhanto.idMap) do
		if phanto ~= v and phanto.data.initialized and phanto.data.targetPlayer == p then
			return true
		end
	end

	return false
end

local function pickTarget(v,exceptionPlayer)
	local backupPlayers = {}

    local highestPlacingPlayers
    local highestPlacement = 0

    for _,p in ipairs(battlePlayer.getActivePlayers()) do
        local data = battlePlayer.getPlayerData(p)

        if targetIsValid(v,p) then
			if p ~= exceptionPlayer and not targetIsAlreadyChased(v,p) then
				local placement = battleItems.getPlayerPlacement(p)

				if placement > highestPlacement then
					highestPlacingPlayers = {p}
					highestPlacement = placement
				elseif placement > 0 and placement == highestPlacement then
					table.insert(highestPlacingPlayers,p)
				end
			end

			table.insert(backupPlayers,p)
        end
    end

    if highestPlacingPlayers ~= nil then
        return RNG.irandomEntry(highestPlacingPlayers)
    end

	return RNG.irandomEntry(backupPlayers)
end

local function getDistanceToTarget(v,targetCenter)
	local sectionObj = v.sectionObj

	local boundary = sectionObj.boundary
    local boundsWidth = boundary.right - boundary.left
    local boundsHeight = boundary.bottom - boundary.top

	local selfCenterX = v.x + v.width*0.5
	local selfCenterY = v.y + v.height*0.5

	local toTargetX = targetCenter.x - selfCenterX
	local toTargetY = targetCenter.y - selfCenterY

	if sectionObj.wrapH then
		toTargetX = absMin(toTargetX, targetCenter.x + boundsWidth - selfCenterX, targetCenter.x - boundsWidth - selfCenterX)
	end

	if sectionObj.wrapV then
		toTargetY = absMin(toTargetY, targetCenter.y + boundsHeight - selfCenterY, targetCenter.y - boundsHeight - selfCenterY)
	end

	return toTargetX,toTargetY
end

local function pickRoamTarget(v)
	local bounds = v.sectionObj.boundary

	return vector(RNG.random(bounds.left + 128,bounds.right - 128),RNG.random(bounds.top + 128,bounds.bottom - 128))
end


local function setAnimBounds(v, typestr)
	local data = v.data._basegame
	local config = NPC.config[v.id]

	data.startframe = config[typestr.."startframe"]
	data.endframe = config[typestr.."endframe"]
end




function bluePhanto.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end

	local data = v.data._basegame
	local config = NPC.config[v.id]
	local cam = camera
	local currentSection = v:mem(0x146, FIELD_WORD)
	local canActivateOffscreen = (config.awakenoffscreen  and  player.section == currentSection)

	--If despawned OR not able to spawn offscreen when in the same section
	if v:mem(0x12A, FIELD_WORD) <= 0 and not canActivateOffscreen then
		--Reset our properties, if necessary
		data.initialized = false
		return;
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE.INACTIVE
		data.startframe = nil
		data.endframe = nil
		v.ai1 = 0
		v.ai2 = 0
		data.timer = 0
		data.startSection = currentSection
		data.targetPlayer = nil

		data.roamTargetPosition = vector.zero2

		data.animationTimer = 0

        data.stunTimer = 0

        data.leaving = false
        data.leaveTimer = 0
        data.leaveDirection = 0

		data.chargeDirection = vector.zero2
		data.chargeTime = 0
        data.chargeCooldown = 0

		data.forceCharge = false

		data.hasClaimedWear = false
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
		data.state = STATE.HOSTAGE
	end


	-------- Execute main AI -----------
	local center = vector.v2(v.x+0.5*v.width, v.y+0.5*v.height)


	-- STATE-AGNOSTIC BEHAVIOR
	local sectionObj = Section(currentSection) or Section(player.section)

	-- Animation handling
	data.startframe = nil
	data.endframe = nil

	-- General-purpose AI timer countdown
	v.ai1 = math.max(0, v.ai1-1)

	-- prevent from despawning when offscreen
	if not data.leaving then
		v:mem(0x124, FIELD_BOOL, true)
		v:mem(0x12A, FIELD_WORD, 180)
		v:mem(0x126, FIELD_BOOL, false)
		v:mem(0x128, FIELD_BOOL, false)
	end

    if v:mem(0x12E,FIELD_WORD) > 0 then
        v:mem(0x12E,FIELD_WORD,10)
    end

	-- Handle the move sound effect, determining the target player and following them across sections
	if data.state == STATE.AWAKEN or data.state == STATE.SHAKE or data.state == STATE.FOLLOW then

		-- If a player took a target item to another section, or I'm just stubborn, follow them
		if  data.targetPlayer ~= nil  and  data.targetPlayer.section ~= currentSection   and not data.leaving  then
            v:mem(0x146, FIELD_WORD, data.targetPlayer.section)
            currentSection = v:mem(0x146, FIELD_WORD)
            v.speedY = RNG.random(-3,0)
            v.x = data.targetPlayer.x + (data.targetPlayer.width - v.width)*0.5
            v.y = data.targetPlayer.sectionObj.boundary.top - v.height
            data.timer = RNG.randomInt(-200, 0)
            data.state = STATE.FOLLOW
		end

		-- Moving sound effect
		v.ai2 = (v.ai2 + 1)%128
		if  v.ai2 == 0  and  data.targetPlayer ~= nil  and  not data.leaving then
			SFX.play(config.moveSound)
		end
	end

	-- Friendly if not tracking the player
	--v.friendly = (data.targetPlayer == nil)  or  data.startedFriendly



	-- INACTIVE
	if data.state == STATE.INACTIVE then
		setAnimBounds(v, "sleep")

        data.targetPlayer = pickTarget(v)

        if data.targetPlayer == nil and config.permanentleavingenabled then
            data.leaving = true

            if v:mem(0x130,FIELD_WORD) > 0 then
                data.leaveDirection = Player(v:mem(0x130,FIELD_WORD)).direction
            end
        end

        data.state = STATE.AWAKEN
		SFX.play(config.moveSound)

		v.ai1 = config.awakenTime
	-- AWAKENING
	elseif data.state == STATE.AWAKEN then
		setAnimBounds(v, "flash")

		if v.ai1 <= 0 then
			if onlinePlayNPC.ownsNPC(v) then
				local isSPB = (config.spbSoundEnabled and RNG.randomInt(1,100) == 1)

				if isSPB then
					SFX.play(config.spbSound)
				else
					SFX.play(config.shakeSound)
				end

				if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
					shakeSoundCommand:send(v,0, isSPB)
				end
			end

			data.state = STATE.SHAKE
			v.ai1 = config.shakeTime
		end
	-- SHAKING
	elseif data.state == STATE.SHAKE then
		setAnimBounds(v, "chase")

		if v.ai1 <= 0 then
			data.state = STATE.FOLLOW
			data.timer = 0
		end

	-- FOLLOWING
	elseif data.state == STATE.FOLLOW then
		setAnimBounds(v, "chase")

		-- Manage chasing and hovering behavior
		local targetCenter
		
		if data.targetPlayer ~= nil then
			local targetP = data.targetPlayer
			targetCenter = vector.v2(targetP.x+0.5*targetP.width, targetP.y+targetP.height-32)
		end


        local toTargetX = 0
        local toTargetY = 0

        if data.leaving then
            toTargetX = data.leaveDirection
            toTargetY = -1
		elseif targetCenter ~= nil then
            toTargetX,toTargetY = getDistanceToTarget(v,targetCenter)
        end

        if data.stunTimer == 0 then
            --[[v.speedX = v.speedX + config.chaseacceleration*math.sign(toTargetX)*config.homingspeed
            v.speedX = math.clamp(v.speedX, -config.chasemaxspeed*config.homingspeed,config.chasemaxspeed*config.homingspeed)

            v.speedY = v.speedY + config.chaseacceleration*math.sign(toTargetY)*config.homingspeed
            v.speedY = math.clamp(v.speedY, -config.chasemaxspeed*config.homingspeed,config.chasemaxspeed*config.homingspeed)]]

			v.speedX = approach(v.speedX,config.chasemaxspeed*config.homingspeed*math.sign(toTargetX),config.chaseacceleration*config.homingspeed)
			v.speedY = approach(v.speedY,config.chasemaxspeed*config.homingspeed*math.sign(toTargetY),config.chaseacceleration*config.homingspeed)
        else
            data.stunTimer = math.max(0,data.stunTimer - 1)
        end

        data.chargeCooldown = math.max(0,data.chargeCooldown - 1)


        -- Leave, eventually
        if not data.leaving and data.targetPlayer ~= nil then
            local playerData = battlePlayer.getPlayerData(data.targetPlayer)

            if (toTargetX*toTargetX + toTargetY*toTargetY) <= config.leaveradius*config.leaveradius then
                data.leaveTimer = data.leaveTimer + 1
            end

            if not targetIsValid(v,data.targetPlayer) or data.leaveTimer >= config.leavetime then
				if config.permanentleavingenabled then
					data.leaveDirection = -math.sign(v.speedX)
					data.leaving = true
				else
					-- Pick a new target instead
					data.targetPlayer = pickTarget(v,data.targetPlayer)
				end
            end
        end

		-- Charge attack
		if not data.leaving and not data.hasClaimedWear and data.stunTimer == 0 and data.chargeCooldown == 0 and config.chargeattackenabled and targetCenter ~= nil and (data.forceCharge or (toTargetX*toTargetX + toTargetY*toTargetY) <= config.chargeradius*config.chargeradius) then
			data.state = STATE.CHARGE_ANTICIPATION
			data.timer = 0

			data.chargeDirection = vector(toTargetX,toTargetY):normalise()
			data.chargeTime = (vector(toTargetX,toTargetY).length + config.chargeadditionaldistance)/config.chargespeed

            data.chargeCooldown = config.chargecooldown
			data.leaveTimer = data.leaveTimer + config.chargereduceleavetime

			data.forceCharge = false

			SFX.play(config.chargeAnticipationSound)
		end

		-- Enter roaming
		if not data.leaving and not config.permanentleavingenabled and data.targetPlayer == nil then
			data.state = STATE.ROAM
			data.timer = 0

			data.roamTargetPosition = pickRoamTarget(v)
		end
	-- CHARGE ANTICIPATION
	elseif data.state == STATE.CHARGE_ANTICIPATION then
		setAnimBounds(v, "chargeanticipation")

		local moveTime = math.min(1,data.timer/(config.chargeanticipationtime*0.8))
		local speed = -data.chargeDirection*(1 - moveTime)*config.chargeanticipationspeed

		v.speedX = speed.x
		v.speedY = speed.y

		if data.timer >= config.chargeanticipationtime then
			data.state = STATE.CHARGE_GO
			data.timer = 0

			SFX.play(config.chargeSound)
		else
			data.timer = data.timer + 1
		end
	-- CHARGE
	elseif data.state == STATE.CHARGE_GO then
		setAnimBounds(v, "charge")

		local accelerationTime = math.min(1,data.timer/config.chargeaccelerationtime)
		local speed = data.chargeDirection*(config.chargespeed*accelerationTime)

		v.speedX = speed.x
		v.speedY = speed.y

		if data.timer >= data.chargeTime then
			data.state = STATE.CHARGE_STOP
			data.timer = 0
		else
			data.timer = data.timer + 1
		end

		-- Hit other NPCs
		local npcs = Colliders.getColliding{a = v,b = NPC.HITTABLE,btype = Colliders.NPC}

		for _,npc in ipairs(npcs) do
			npc:harm(HARM_TYPE_NPC)
		end
	-- CHARGE STOP
	elseif data.state == STATE.CHARGE_STOP then
		setAnimBounds(v, "charge")

		local accelerationTime = 1 - math.min(1,data.timer/config.chargedecelerationtime)
		local speed = data.chargeDirection*(config.chargespeed*accelerationTime)

		v.speedX = speed.x
		v.speedY = speed.y

		if data.timer >= config.chargedecelerationtime then
			data.state = STATE.FOLLOW
			data.timer = 0
		else
			data.timer = data.timer + 1
		end
	-- HOSTAGE
	elseif data.state == STATE.HOSTAGE then
        data.targetPlayer = nil
		setAnimBounds(v, "sleep")

		if v:mem(0x12C, FIELD_WORD) <= 0 then
			v:mem(0x136, FIELD_BOOL, false)
			data.state = STATE.INACTIVE
			data.timer = 0

            v.speedX = 0
            v.speedY = 0
		end
	-- ROAM
	elseif data.state == STATE.ROAM then
		-- Look to see if there might be a valid target
		data.targetPlayer = pickTarget(v)

		if data.targetPlayer ~= nil then
			-- Go back to chasing
			data.state = STATE.FOLLOW
			data.timer = 0
		else
			-- Move around to random targets
			local toTargetX,toTargetY = getDistanceToTarget(v,data.roamTargetPosition)

			v.speedX = approach(v.speedX,config.chasemaxspeed*config.homingspeed*math.sign(toTargetX),config.chaseacceleration*config.homingspeed)
			v.speedY = approach(v.speedY,config.chasemaxspeed*config.homingspeed*math.sign(toTargetY),config.chaseacceleration*config.homingspeed)

			if math.sqrt(toTargetX*toTargetX + toTargetY*toTargetY) <= 192 then
				data.roamTargetPosition = pickRoamTarget(v)
			end
		end
	end

	-- Put on players
	if config.wearable
	and v.heldIndex == 0
	and (onlinePlay.currentMode == onlinePlay.MODE_OFFLINE or onlinePlayNPC.getUIDFromNPC(v) ~= nil)
	and not (data.state == STATE.INACTIVE or data.state == STATE.AWAKEN or data.state == STATE.SHAKE)
	then
		for _,p in ipairs(Player.getIntersecting(v.x,v.y,v.x + v.width,v.y + v.height)) do
			phantoTryWear(v,p)
		end
	end

	data.animationTimer = data.animationTimer + 1
end

function bluePhanto.onDrawNPC(v)
	local data = v.data._basegame
	local config = NPC.config[v.id]

    if v.despawnTimer <= 0 then
        return
    end

    if v.forcedState == NPCFORCEDSTATE_DROPPED_ITEM and v.forcedCounter1%3 == 0 then
        return
    end

	local shakeExtra = 0
	if data.state == STATE.SHAKE and not Defines.levelFreeze then
		shakeExtra = math.floor((lunatime.tick()%8)/4)
	end

	local animlength = 1
	if data.startframe ~= nil and data.endframe ~= nil then
		animlength = data.endframe - data.startframe + 1
	end

	local frame = 0

	if data.startframe ~= nil and data.endframe ~= nil then
		frame = math.floor(data.animationTimer/config.framespeed)%(data.endframe - data.startframe + 1) + data.startframe
		frame = npcutils.getFrameByFramestyle(v,{frame = frame})
	end

	npcutils.drawNPC(v, {
		frame = frame,
		xOffset = config.gfxoffsetx + shakeExtra,
		opacity = (data.hasClaimedWear and 0.75) or 1,
	})
	npcutils.hideNPC(v)
end


function bluePhanto.onNPCHarm(eventObj, v, reason, culprit)
    if not bluePhanto.idMap[v.id] then
        return
    end

    if reason == HARM_TYPE_TAIL or reason == HARM_TYPE_SWORD then
        if type(culprit) == "Player" then
            if (culprit.x + culprit.width) > (v.x + v.width*0.5) then
                v.speedX = -5
            else
                v.speedX = 5
            end
        else
            v.speedX = -math.sign(v.speedX)*5
        end

        v.data._basegame.stunTimer = 16
        v.data._basegame.forceCharge = true

        SFX.play(9)

        eventObj.cancelled = true
    end
end


function bluePhanto.onInitAPI()
    registerEvent(bluePhanto, "onNPCHarm")
end


return bluePhanto