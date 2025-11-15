--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local whistle = require("npcs/ai/whistle")
local rng = require("rng")


local battlePlayer = require("scripts/battlePlayer")
local battleItems = require("scripts/battleItems")

local onlinePlay = require("scripts/onlinePlay")
local onlinePlayNPC = require("scripts/onlinePlay_npc")


local npcID = NPC_ID
local phanto = {}

local phantoSettings = {
    id = npcID,

	--Sprite size
	gfxheight = 128,
	gfxwidth = 133,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 133,
	height = 128,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 16,
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


	--Define custom properties below
	awakenoffscreen = true,

	enterawayfromplayer = false,

	flashstartframe=2,
	flashendframe=3,

	sleepstartframe=2,
	sleependframe=3,

	chasestartframe=7,
    chaseendframe=8,

	awakenTime = 32,
	shakeTime = 65,
    
    stoptype = 2 -- behaviour when a key is let go of: 0=stops, 1=continues, 2=continues even across sections
}

npcManager.setNpcSettings(phantoSettings)
npcManager.registerHarmTypes(npcID, {HARM_TYPE_TAIL, HARM_TYPE_SWORD})

function phanto.onInitAPI()
    npcManager.registerEvent(npcID, phanto, "onTickNPC")
    npcManager.registerEvent(npcID, phanto, "onDrawNPC")

    registerEvent(phanto, "onNPCHarm")
end


function phanto.onNPCHarm(eventObj, v, reason, culprit)
	if v.id == npcID then
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

			SFX.play(9)

			eventObj.cancelled = true
		end
	end
end


--Custom local definitions below
local STATE = {INACTIVE=1, AWAKEN=2, SHAKE=3, FOLLOW=4, HOSTAGE=5}
local soundfx = {
	awaken = Misc.resolveSoundFile("phanto-awaken"),
	shake = Misc.resolveSoundFile("phanto-shake"),
	move = Misc.resolveSoundFile("phanto-move")
}

local spbSound = Misc.resolveSoundFile("resources/spb")


local shakeSoundCommand = onlinePlayNPC.createNPCCommand("firstPlacePhanto_shakeSound",onlinePlay.IMPORTANCE_MAJOR)

function shakeSoundCommand.onReceive(npc,sourcePlayerIdx, isSPB)
	if isSPB then
		SFX.play(spbSound)
	else
		SFX.play(soundfx.shake)
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


local function pickTarget(ownerIdx)
    local highestPlacingPlayers
    local highestPlacement = 0

    for _,p in ipairs(battlePlayer.getActivePlayers()) do
        local data = battlePlayer.getPlayerData(p)

        if not data.isDead and p.idx ~= ownerIdx and not battlePlayer.playersAreOnSameTeam(p.idx,ownerIdx) then
            local placement = battleItems.getPlayerPlacement(p)

            if placement > highestPlacement then
                highestPlacingPlayers = {p}
                highestPlacement = placement
            elseif placement > 0 and placement == highestPlacement then
                table.insert(highestPlacingPlayers,p)
            end
        end
    end

    if highestPlacingPlayers ~= nil then
        return RNG.irandomEntry(highestPlacingPlayers)
    end
end


local function setAnimBounds(v, typestr)
	local data = v.data._basegame
	local config = NPC.config[v.id]

	data.startframe = config[typestr.."startframe"]
	data.endframe = config[typestr.."endframe"]
end




function phanto.onTickNPC(v)
	--Don't act during time freeze
	if  Defines.levelFreeze then  return  end

	local data = v.data._basegame
	local config = NPC.config[v.id]
	local cam = camera
	local currentSection = v:mem(0x146, FIELD_WORD)
	local canActivateOffscreen = (config.awakenoffscreen  and  player.section == currentSection)


	--If despawned OR not able to spawn offscreen when in the same section
	if  v:mem(0x12A, FIELD_WORD) <= 0  and  not canActivateOffscreen  then
		--Reset our properties, if necessary
		data.initialized = false
		return;
	end

	local settings = v.data._settings

	--Initialize
	if  not data.initialized  then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE.INACTIVE
		data.startframe = nil
		data.endframe = nil
		v.ai1 = 0
		v.ai2 = 0
		data.timer = 0
		data.timerIncrement = 1
		data.startSection = currentSection
		data.currentScreenLeft = v.x
		data.targetPlayer = nil
		data.exitSide = -1
		data.enteredSide = -1

		data.animationTimer = 0

        data.stunTimer = 0

        data.leaving = false
        data.leaveTimer = 0
        data.leaveDirection = 0

		if  data.startedFriendly == nil  then
			data.startedFriendly = v.friendly
		end
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
	local sectionObj = Section(currentSection)  or  Section(player.section)

	-- Animation handling
	data.startframe = nil
	data.endframe = nil

	-- General-purpose AI timer countdown
	v.ai1 = math.max(0, v.ai1-1)

	-- prevent from despawning when offscreen
	if  (data.state ~= STATE.INACTIVE  or  canActivateOffscreen)  and not data.leaving  then
		v:mem(0x124, FIELD_BOOL, true)
		v:mem(0x12A, FIELD_WORD, 180)
		v:mem(0x126, FIELD_BOOL, false)
		v:mem(0x128, FIELD_BOOL, false)
	end

    if v:mem(0x12E,FIELD_WORD) > 0 then
        v:mem(0x12E,FIELD_WORD,10)
    end

	-- Handle the move sound effect, determining the target player and following them across sections
	if  data.state == STATE.AWAKEN  or  data.state == STATE.SHAKE  or  data.state == STATE.FOLLOW  then
		--[[if not whistle.getActive() then
			if  config.stoptype == 0 then
				data.targetPlayer = nil
			end
			for  k,n in NPC.iterate(settings.targetId) do
				if sectionToCheck == -1 or n.section == sectionToCheck then
					local pID = n:mem(0x12C,FIELD_WORD)
					if  pID > 0  then
						data.targetPlayer = Player(pID)
						heldDetected = true
						break;
					end
				end
			end
			if settings.targetId == 31 and not heldDetected then
				for k,n in ipairs(Player.get()) do
					if n:mem(0x12, FIELD_BOOL) then
						data.targetPlayer = n
						heldDetected = true
						break
					end
				end
			end
			if settings.targetId == 134 and not heldDetected then
				for k,n in ipairs(Player.get()) do
					if n:mem(0x08, FIELD_WORD) > 0 then
						data.targetPlayer = n
						heldDetected = true
						break
					end
				end
			end
		else
			heldDetected = true
			data.targetPlayer = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
		end]]

		-- If a player took a target item to another section, or I'm just stubborn, follow them
		if  data.targetPlayer ~= nil  and  data.targetPlayer.section ~= currentSection   and not data.leaving  then
            v:mem(0x146, FIELD_WORD, data.targetPlayer.section)
            currentSection = v:mem(0x146, FIELD_WORD)
            v.speedY = rng.random(-3,0)
            v.x = data.targetPlayer.x + (data.targetPlayer.width - v.width)*0.5
            v.y = data.targetPlayer.sectionObj.boundary.top - v.height
            data.timer = RNG.randomInt(-200, 0)
            data.state = STATE.FOLLOW
		end

		-- Moving sound effect
		v.ai2 = (v.ai2 + 1)%128
		if  v.ai2 == 0  and  data.targetPlayer ~= nil  and  not data.leaving then
			SFX.play(soundfx.move)
		end
	end

	-- Friendly if not tracking the player
	--v.friendly = (data.targetPlayer == nil)  or  data.startedFriendly



	-- INACTIVE
	if  data.state == STATE.INACTIVE  then
		setAnimBounds(v, "sleep")

        data.targetPlayer = pickTarget(v:mem(0x130,FIELD_WORD))

        if data.targetPlayer == nil then
            data.leaving = true

            if v:mem(0x130,FIELD_WORD) > 0 then
                data.leaveDirection = Player(v:mem(0x130,FIELD_WORD)).direction
            end
        end

        data.state = STATE.AWAKEN
		SFX.play(soundfx.move)
        
		--[[if whistle.getActive() then
			data.state = STATE.AWAKEN
			SFX.play(soundfx.move)
		end

		for  k,n in NPC.iterate(settings.targetId) do
			if n.section == data.startSection and n:mem(0x12C,FIELD_WORD) > 0  then
				data.state = STATE.AWAKEN
				SFX.play(soundfx.move)
				break;
			end
		end
		if settings.targetId == 31 and data.state ~= STATE.AWAKEN then
			for k,n in ipairs(Player.get()) do
				if n:mem(0x12, FIELD_BOOL) then
					data.state = STATE.AWAKEN
					SFX.play(soundfx.move)
					break
				end
			end
		end
		if settings.targetId == 134 and data.state ~= STATE.AWAKEN then
			for k,n in ipairs(Player.get()) do
				if n:mem(0x08, FIELD_WORD) > 0 then
					data.state = STATE.AWAKEN
					SFX.play(soundfx.move)
					break
				end
			end
		end]]
		v.ai1 = config.awakenTime


	-- AWAKENING
	elseif  data.state == STATE.AWAKEN  then
		setAnimBounds(v, "flash")

		if  v.ai1 <= 0  then
			if onlinePlayNPC.ownsNPC(v) then
				local isSPB = (RNG.randomInt(1,50) == 1)

				if isSPB then
					SFX.play(spbSound)
				else
					SFX.play(soundfx.shake)
				end

				if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
					shakeSoundCommand:send(v,0, isSPB)
				end
			end

			data.state = STATE.SHAKE
			v.ai1 = config.shakeTime
		end


	-- SHAKING
	elseif  data.state == STATE.SHAKE  then
		setAnimBounds(v, "chase")

		if  v.ai1 <= 0  then
			data.state = STATE.FOLLOW
			data.timer = 0
		end


	-- FOLLOWING
	elseif  data.state == STATE.FOLLOW  then
		setAnimBounds(v, "chase")

		-- Manage chasing and hovering behavior
		local boundary = sectionObj.boundary
		--local sectionW = boundary.right - boundary.left
        local boundsWidth = boundary.right - boundary.left
        local boundsHeight = boundary.bottom - boundary.top

		local targetCenter
		--local camCenter = vector(cam.x+0.5*cam.width, cam.y+0.5*cam.height)
		
		if  data.targetPlayer ~= nil  then
			local targetP = data.targetPlayer
			targetCenter = vector.v2(targetP.x+0.5*targetP.width, targetP.y+targetP.height-32)
			data.exitSide = -math.sign(targetCenter.y-center.y)
			if  data.exitSide == 0  then
				data.exitSide = 1
			end

			--[[if  data.enteredSide == nil  then
				data.enteredSide = data.exitSide
				if  config.enterawayfromplayer  and  ((v.y + v.height <= cam.y  and  targetCenter.y < camCenter.y)  or  (v.y >= cam.y+cam.height  and  targetCenter.y > camCenter.y))  then
					--Misc.dialog("SWITCHING SIDES")
					v.y = cam.y + 0.5*cam.height - (400+v.height)*data.enteredSide
				end
			end]]

		else
			--targetCenter = camCenter + vector(0, cam.width*data.exitSide)
			data.enteredSide = nil
		end


        local toTargetX
        local toTargetY

        if data.leaving then
            toTargetX = data.leaveDirection
            toTargetY = -1
        else
            toTargetX = targetCenter.x - center.x
            toTargetY = targetCenter.y - center.y

            if sectionObj.wrapH then
                toTargetX = absMin(toTargetX, targetCenter.x + boundsWidth - center.x, targetCenter.x - boundsWidth - center.x)
            end
    
            if sectionObj.wrapV then
                toTargetY = absMin(toTargetY, targetCenter.y + boundsHeight - center.y, targetCenter.y - boundsHeight - center.y)
            end
        end

        if data.stunTimer == 0 then
            v.speedX = v.speedX + 0.15*math.sign(toTargetX)*config.homingspeed
            v.speedX = math.clamp(v.speedX, -5*config.homingspeed,5*config.homingspeed)

            v.speedY = v.speedY + 0.15*math.sign(toTargetY)*config.homingspeed
            v.speedY = math.clamp(v.speedY, -5*config.homingspeed,5*config.homingspeed)
        else
            data.stunTimer = math.max(0,data.stunTimer - 1)
        end


        -- Leave, eventually
        if not data.leaving then
            local playerData = battlePlayer.getPlayerData(data.targetPlayer)

            if (toTargetX*toTargetX + toTargetY*toTargetY) <= 320*320 then
                data.leaveTimer = data.leaveTimer + 1
            end

            if playerData.isDead or data.leaveTimer >= 512 then
                data.leaveDirection = -math.sign(v.speedX)
                data.leaving = true
            end
        end


		-- Horizontal movement
		--[[local horzCycleDegrees = (lunatime.toSeconds(data.timer))*50*config.speed

		if  sectionW > cam.width  or  not sectionObj.isLevelWarp  then
			-- Shift to lax camera-based following depending on the section width and settings
			data.currentScreenLeft = math.lerp(data.currentScreenLeft, cam.x - 0.5*v.width, math.lerp(0,0.125, math.min(180,horzCycleDegrees)/180))
		end

	    v.x = data.currentScreenLeft + cam.width*(0.5 + 0.5*math.cos(math.rad((horzCycleDegrees) % 360 + 180)))
		center = vector.v2(v.x+0.5*v.width, v.y+0.5*v.height)


		-- Wrap around sections
		if  sectionObj.isLevelWarp  then

			if  center.x > boundary.right + 0.5*v.width  then
				v.x = v.x - sectionW - v.width

			elseif  center.x < boundary.left - 0.5*v.width  then
				v.x = v.x + sectionW + v.width
			end
		end]]


	-- HOSTAGE
	elseif  data.state == STATE.HOSTAGE  then
		--[[local pID = v:mem(0x12C,FIELD_WORD)
		data.targetPlayer = nil
		if  pID > 0  then
			data.targetPlayer = Player(pID)
		end
		if settings.targetId == 31 and data.targetPlayer == nil then
			for k,n in ipairs(Player.get()) do
				if n:mem(0x12, FIELD_BOOL) then
					data.targetPlayer = n
					break
				end
			end
		end
		if settings.targetId == 134 and data.targetPlayer == nil then
			for k,n in ipairs(Player.get()) do
				if n:mem(0x08, FIELD_WORD) > 0 then
					data.targetPlayer = n
					break
				end
			end
		end]]

        data.targetPlayer = nil
		setAnimBounds(v, "sleep")

		if  v:mem(0x12C, FIELD_WORD) <= 0  then
			v:mem(0x136, FIELD_BOOL, false)
			data.currentScreenLeft = v.x
			data.state = STATE.INACTIVE
			data.timer = 0

            v.speedX = 0
            v.speedY = 0
		end
	end

	data.animationTimer = data.animationTimer + 1


    --Text.print(data.leaveTimer,v.x - camera.x,v.y - camera.y)
    --Text.print(v:mem(0x132,FIELD_WORD),v.x - camera.x,v.y - camera.y + 16)


	-- DEBUG
	--[[
	--data.pos = vector.v2(math.floor(center.x), math.floor(center.y))
	--data.speed = vector.v2(math.floor(v.speedX), math.floor(v.speedY))
	local str = ""
	for  key,val in pairs(data)  do
		str = str .. key .. ": " .. tostring(val) .. "<br>"
	end
	textplus.print {text=str, x=20, y=20, priority = 0.985, color=Color.white, font=FONT_BASIC, align="topleft", pivot={0,0}, xscale=1, yscale=1}
	--data.pos = nil
	--data.speed = nil
	--]]

end

function phanto.onDrawNPC(v)
	local data = v.data._basegame
	local config = NPC.config[v.id]

    if v.despawnTimer <= 0 then
        return
    end

    if v.forcedState == NPCFORCEDSTATE_DROPPED_ITEM and v.forcedCounter1%3 == 0 then
        return
    end

	local shakeExtra = 0
	if  data.state == STATE.SHAKE and Defines.levelFreeze == false then
		shakeExtra = math.floor((lunatime.tick()%8)/4)
	end

	local animlength = 1
	if  data.startframe ~= nil  and  data.endframe ~= nil  then
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
	})
	npcutils.hideNPC(v)
end




--Gotta return the library table!
return phanto