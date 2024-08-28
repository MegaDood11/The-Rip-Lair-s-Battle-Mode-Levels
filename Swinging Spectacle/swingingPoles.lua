--[[
	Swinging Poles v1.1.1 by "Master" of Disaster
	SPECIAL ONLINE VERSION!! 
]]

local swingingPoles = {
	followPoleCam = true,	-- whether the camera should follow the pole
	swingAccel = 0.06,		-- how fast the player builds up speed when swinging back and forth
	blurspeed = 24,			-- the speed a player needs to reach to change jumping behavior (so you don't have to time where to jump)
	effectID = 912,			-- the id of the afterimage effect
}

local npcIDs = {}


local npcManager = require("npcManager")
local playerManager = require("playerManager")
local booMushroom = require("scripts/booMushroom")
local onlinePlay = require("scripts/onlinePlay")
local onlinePlayPlayers = require("scripts/onlinePlay_players")
local battlePlayer = require("scripts/battlePlayer")

local starShader = Shader.fromFile(nil, Misc.multiResolveFile("starman.frag", "shaders\\npc\\starman.frag"))

local jumpOffCommand = onlinePlay.createCommand("jumpOffSwingingPole",onlinePlay.IMPORTANCE_MAJOR)
local dropOffCommand = onlinePlay.createCommand("dropOffSwingingPole",onlinePlay.IMPORTANCE_MAJOR)
local swingCommand = onlinePlay.createCommand("swingOnSwingingPole",onlinePlay.IMPORTANCE_MAJOR)

local swingSprite = {	-- done this way so if need be, you can use a different frame than the jumping frame for swinging
	[CHARACTER_MARIO] = 4,
	[CHARACTER_LUIGI] = 4,
	[CHARACTER_PEACH] = 8,
	[CHARACTER_TOAD] = 8,
	[CHARACTER_LINK] = 10
}


function swingingPoles.register(id)
	--npcManager.registerEvent(id, swingingPoles, "onTickNPC")
	npcManager.registerEvent(id, swingingPoles, "onTickEndNPC")
	--npcManager.registerEvent(id, swingingPoles, "onDrawNPC")
	--registerEvent(swingingPoles, "onNPCHarm")
	npcIDs[id] = true
end

registerEvent(swingingPoles,"onTick")
registerEvent(swingingPoles,"onDraw")
registerEvent(swingingPoles,"onCameraUpdate")	-- for locking the camera when on a pole
registerEvent(swingingPoles,"onNPCKill")

local function activeCam(p)	-- returns the camera object the player is shown on
	local cam = camera
	for _,c in ipairs(Camera.get()) do
		if table.contains(Player.getIntersecting(c.bounds.left, c.bounds.top, c.bounds.right, c.bounds.bottom), p) then
			return c
		end
	end
	return cam
end

local function interferesWithBoundrary(p,x,y)		-- whether the set positions of the camera interfere with the border. If so, return a string according to which border it interferes
	local sectionBound = Section(p.section).boundary
	local interferes = "NO"
	local cam = activeCam(p)

	if x < sectionBound.left or x + cam.width > sectionBound.right then
		interferes = "HORIZONTAL"
	end
	if y < sectionBound.top or y + cam.height > sectionBound.bottom then
		if interferes == "HORIZONTAL" then
			interferes = "BOTH"
		else
			interferes = "VERTICAL"
		end
	end
	
	return interferes
end

local function limitControlsOnPole(p)
	p:mem(0x00,FIELD_BOOL,false)		-- no double jump for Tanooki Toad as it ruins jumping off
	p:mem(0x10,FIELD_WORD,0)			-- make the fairy timer run out immediately
	p:mem(0x14,FIELD_WORD,4)			-- no sword slashing on a pole
	p:mem(0x18,FIELD_BOOL,false)		-- no hover for peach
	p:mem(0x1C,FIELD_WORD,0)			-- hover timer ends immediately
	p:mem(0x3C,FIELD_BOOL,false)		-- no sliding
	p:mem(0x4A,FIELD_BOOL,false)		-- no statue
	p:mem(0x4C,FIELD_WORD,4)			-- no transforming into statue for 4 frames
	p:mem(0x160,FIELD_WORD,4)			-- no throwing projectiles
	p:mem(0x162,FIELD_WORD,4)			-- no throwing link projectiles
	p:mem(0x16E,FIELD_BOOL,false)		-- no flying on my pole
	p:mem(0x164,FIELD_WORD,0)			-- no tailswiping
end

local function isOnGroundRedigit(p) -- grounded player check. surprisingly, doing it the redigit way is more reliable than player:is On Ground()
    return (
        p.speedY == 0
        or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC (this is -1 when standing on a moving block. thanks redigit.)
        or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end

local function ultimateSlip(p)		-- removes friction, but more importantly uncaps player speed
    p:mem(0x138, FIELD_FLOAT, p.speedX)
    p.speedX = 0
end


local function getPlayerSprites(p)	-- looks whether a spritesheet for the given player and costume exists, and if not makes one by default
	local pCostume = "NORMAL"		-- find out the player's costume. Normal if no costume is used
	if Player.getCostume(p.character) then
		pCostume = Player.getCostume(p.character)
	end
	
	local success, spriteSheet = pcall(Graphics.loadImageResolved,p.character .. "-" .. pCostume .. "-on-pole.png")
	-- if there is a spritesheet for swinging, open it. If not, success is false
	
	local spriteData = {
		customSprite = success,	-- true if there is a custom spritesheet. It uses different drawing args if not
		offsetX = 0,
		offsetY = 0,
		scale = 2,		-- if 1, the image itself is already 2x2, if 2 it will get multiplied by 2 afterwards.
		frameX = (p.powerup - 1),
		frameY = p.data.swingingPoles.frame,
		direction = p.direction
	}
	
	if not success then	-- no spritesheet is found. Now it's time to get funny with making a default spritesheet
		spriteSheet = playerManager.getCostumeImage(p.character,p.powerup)
		if spriteSheet == nil then	-- not using a costume. Manually get the proper sprite
			if p.character == 1 then
				spriteSheet = Graphics.loadImageResolved("mario-" .. p.powerup .. ".png")
			elseif p.character == 2 then
				spriteSheet = Graphics.loadImageResolved("luigi-" .. p.powerup .. ".png")
			elseif p.character == 3 then
				spriteSheet = Graphics.loadImageResolved("peach-" .. p.powerup .. ".png")
			elseif p.character == 4 then
				spriteSheet = Graphics.loadImageResolved("toad-" .. p.powerup .. ".png")
			elseif p.character == 5 then
				spriteSheet = Graphics.loadImageResolved("link-" .. p.powerup .. ".png")
			end
		end
		local frameX, frameY = Player.convertFrame(swingSprite[p.character], p.direction)
		local settings = p:getCurrentPlayerSetting()
		local offsetX = settings:getSpriteOffsetX(frameX,frameY)
		local offsetY = settings:getSpriteOffsetY(frameX,frameY)
		
		spriteData.offsetX = offsetX + p.width * 1.5
		spriteData.offsetY = offsetY + p.width - 4
		spriteData.scale = 1
		spriteData.frameX = frameX
		spriteData.frameY = frameY
		spriteData.direction = 1
	end
	
	return spriteSheet, spriteData
end

function swingingPoles.canSwing(p)
	local bdata = battlePlayer.getPlayerData(p)
	return (
	
	not (p:mem(0x148,FIELD_WORD) == 2) and 	-- left collision
	not (p:mem(0x14C,FIELD_WORD) == 2) and 	-- right collision
	not (p:mem(0x14A,FIELD_WORD) == 2) and 	-- top collision
	not (p:mem(0x146,FIELD_WORD) == 2) and	-- bottom collision
	not p:mem(0x36,FIELD_BOOL)	and			-- not In water
	not p:mem(0x06,FIELD_BOOL)	and			-- not in quicksand
	not (p:mem(0x40,FIELD_WORD) > 0) and	-- not Climbing
	not p:mem(0x44, FIELD_BOOL) and			-- not Riding a rainbow shell
	not p:mem(0x13C, FIELD_BOOL) and 		-- alive
	not p.holdingNPC and					-- not holding anything
	p.mount == 0 and						-- not on a Yoshi or Boot
	not p.isMega and						-- not mega
	not p.keys.down and						-- not holding down
	p.deathTimer == 0 and					-- still alive
	Level.winState() == 0 and				-- has not finished the level yet
	bdata.respawnTimer == 0					-- is not currently respawning
	)
end

function swingingPoles.dropOff(p)
	local data = p.data.swingingPoles
	data.onPole = false
	p.speedX = math.abs(data.swingSpeed * 0.25) * data.movementDirection + data.extraSpeedX
	p.speedY = 0
	data.rootNPC = nil
	data.noPoleTimer = 30
end

function swingingPoles.jumpOff(p)	-- make the player jump off the swinging pole
	local data = p.data.swingingPoles
	
	if p.keys.altJump == KEYS_PRESSED and onlinePlayPlayers.ownsPlayer(p) then
		p:mem(0x50,FIELD_BOOL,true)	-- spinjump off
		if onlinePlayPlayers.canMakeSound(p) then
			SFX.play(33)					-- spinning sfx
		end
	else
		if onlinePlayPlayers.canMakeSound(p) then
			SFX.play(1)					-- jumping sfx
		end
	end
	data.onPole = false
	local swingSpeedX = 0
	local swingSpeedY = 0
	
	if math.abs(data.swingSpeed) < swingingPoles.blurspeed then	
		-- jumping off normally. Takes the timing of the jump into consideration
		swingSpeedX = math.abs(data.swingSpeed * 0.5) * data.movementDirection + data.extraSpeedX
		swingSpeedY = math.abs(data.swingSpeed) * 0.5* data.LaunchDirectionY - 4 + data.extraSpeedY 
	else
		-- jumping off when swinging fast. Jump off in the direction you are holding
		local swingDir = p.direction
		if p.keys.right and onlinePlayPlayers.ownsPlayer(p) then
			swingDir = 1
		elseif p.keys.left and onlinePlayPlayers.ownsPlayer(p) then
			swingDir = -1
		end
		swingSpeedX = math.abs(data.swingSpeed * 0.45) * swingDir
		swingSpeedY = - math.abs(data.swingSpeed * 0.45) - 4
	end
	
	p.speedX = swingSpeedX
	p.speedY = swingSpeedY

	if math.abs(swingSpeedX) > 6 then
		data.isFast = true
	end
	data.rootNPC = nil
end

function swingingPoles.onPoleBehaviour(p)	-- all logic for swinging on a swinging pole
	local data = p.data.swingingPoles
	data.noPoleTimer = 15	
	limitControlsOnPole(p)
	
	local newX = - p.width * 0.5 +  data.poleX + data.posOffsetX	
	local newY = - p.height * 0.5 + data.poleY + data.posOffsetY
	if math.abs(newX - p.x) < 64 and math.abs(newY - p.y) < 64 then
		p.x = newX
		p.y = newY
		p.speedY = -0.00001
		p.speedX = 0
	else			-- too far away, perhaps because of a ?-shroom. Exit pole then
		--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
			--dropOffCommand:send(0,p.idx)
		--end
		swingingPoles.dropOff(p)
	end
	p:setFrame(-50) -- make the player invisible in hopes that the player outline doesn't show up (when in onDraw, it does sadly)
	
	-- Accelerate the player
	if p.keys.right then
		data.swingSpeed = math.min(32,data.swingSpeed + swingingPoles.swingAccel)
	elseif p.keys.left then
		data.swingSpeed = math.max(-32,data.swingSpeed - swingingPoles.swingAccel)
	end
	
	-- Makes the speed change actually do something
	data.swingValue =  data.swingValue + data.swingSpeed * 0.01
	
	
	-- There is this outlandsish concept, called "gravity"
	data.swingSpeed = data.swingSpeed - 0.4 * math.sin(data.swingValue)

	
	data.posOffsetX = p.width * math.sin(data.swingValue)	-- moves the player along the pole
	data.posOffsetY = p.width * math.cos(data.swingValue)
	
	
	-- In which direction is the player moving?
	if data.posOffsetY * data.swingSpeed > 0 then
		data.movementDirection = 1
	else
		data.movementDirection = -1
	end
	if data.posOffsetX * data.swingSpeed > 0 then
		data.LaunchDirectionY = -1
	else
		data.LaunchDirectionY = 1
	end

	data.rotation = -math.deg(data.swingValue)	-- set the players rotation


	if math.abs(data.swingSpeed) > 6 then	-- if the player is fast enough to change frame
		data.frame = 1
		if math.abs(data.swingSpeed) > swingingPoles.blurspeed then	-- when it starts to become uncontrollable, have particles
			if not data.fastspinning then		-- give the player a little speed bonus when they reach blurspeed so they don't lose it immediately
				data.swingSpeed = data.swingSpeed + 3 * p.direction
			end
			data.fastspinning = true
			if data.effecttimer == 0 and (onlinePlayPlayers.ownsPlayer(p) or not booMushroom.isActive(p)) then
				local variant = p.powerup + 7 * (p.character - 1)
				local effect = Effect.spawn(swingingPoles.effectID,p.x + p.width * 0.5, p.y + p.height * 0.5,variant)
				effect.angle = data.rotation
				effect.direction = p.direction
				effect.priority = -26
				data.effecttimer = 1
			else
				data.effecttimer = data.effecttimer - 1
			end
		else
			data.fastspinning = false
		end
	else
		data.frame = 0		-- slow ass player moment
	end
	
	if data.rootNPC then	-- if there's an npc to hang on, do stuff.
		local v = data.rootNPC
		data.poleX = v.x + v.width * 0.5
		data.poleY = v.y + v.height * 0.5
		data.extraSpeedY = v.speedY + v.layerObj.speedY
		data.extraSpeedX = v.speedX + v.layerObj.speedX
		if v.isHidden then
			--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
               -- dropOffCommand:send(0,p.idx)
           -- end
			swingingPoles.dropOff(p)
		end
		if swingingPoles.followPoleCam and p.forcedState == 0 then	-- only move camera when the player is not in a forced state
			local cam = activeCam(p)
			if interferesWithBoundrary(p,cam.x + (data.poleX - data.prevPoleX), cam.y + (data.poleY - data.prevPoleY)) ~= "HORIZONTAL" and 
					interferesWithBoundrary(p,cam.x + (data.poleX - data.prevPoleX), cam.y + (data.poleY - data.prevPoleY)) ~= "BOTH" then
				data.setX = data.setX + (data.poleX - data.prevPoleX)
			end
			if interferesWithBoundrary(p,cam.x + (data.poleX - data.prevPoleX), cam.y + (data.poleY - data.prevPoleY)) ~= "VERTICAL" and 
					interferesWithBoundrary(p,cam.x + (data.poleX - data.prevPoleX), cam.y + (data.poleY - data.prevPoleY)) ~= "BOTH"  then
				data.setY = data.setY + (data.poleY - data.prevPoleY)

			end
		end
		data.prevPoleY = data.poleY
		data.prevPoleX = data.poleX
	else
		data.extraSpeedX = 0
		data.extraSpeedY = 0
	end
	
	if (p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED) then	-- jump off
		--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
			--jumpOffCommand:send(0,p.idx)
		--end
		swingingPoles.jumpOff(p)
	end
	if not swingingPoles.canSwing(p) then		-- if the player can't swing anymore, stop swinging (duh)
		--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
			--dropOffCommand:send(0,p.idx)
		--end
		swingingPoles.dropOff(p)
	end
	if data.rootNPC then				-- if the player is about to crash into a wall, stop the swinging already
		if data.rootNPC.data.collidesWall or
				math.abs(data.rootNPC.x + data.rootNPC.width * 0.5 - p.x - p.width * 0.5) > 64 or
				math.abs(data.rootNPC.y + data.rootNPC.height * 0.5 - p.y - p.height * 0.5) > 64 then
			--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
				--dropOffCommand:send(0,p.idx)
			--end
			swingingPoles.dropOff(p)
		end
	end
end

function jumpOffCommand.onReceive(sourcePlayerIdx, playerIdx)
	local p = Player(playerIdx)
	swingingPoles.jumpOff(p)
end

function dropOffCommand.onReceive(sourcePlayerIdx, playerIdx)
	local p = Player(playerIdx)
	swingingPoles.dropOff(p)
end

function swingCommand.onReceive(sourcePlayerIdx, playerIdx)
	local p = Player(playerIdx)
	swingingPoles.onPoleBehaviour(p)
end

function swingingPoles.onTickEndNPC(v)
	local data = v.data
	if not data.nowallCollider then
		data.nowallCollider = Colliders.Circle(v.x + v.width * 0.5,v.y + v.height * 0.5,player.width)
	end
	
	
	data.nowallCollider.x = v.x + v.width * 0.5		-- the collider is there so the player can't glitch into walls
	data.nowallCollider.y = v.y + v.height * 0.5
	data.nowallCollider.radius = player.width + 6

	
	data.collidesWall = false
	for _, b in ipairs(Colliders.getColliding{a = data.nowallCollider, btype = Colliders.BLOCK, filter = function(o) if not (o.isHidden or Block.NONSOLID_MAP[o.id] or Block.SIZEABLE_MAP[o.id] or Block.SEMISOLID_MAP[o.id]) then return true end end}) do
		data.collidesWall = true
	end
	
	
	data.poleTaken = false		-- check whether someone is already on the pole
	for _,p in ipairs(Player.get()) do
		if p.data.swingingPoles.rootNPC == v then
			data.poleTaken = true
		end
	end
	
	for _,p in ipairs(Player.get()) do
		local pdata = p.data.swingingPoles
		if Colliders.collide(v,p) and pdata.noPoleTimer == 0 and swingingPoles.canSwing(p) and not data.collidesWall and not data.poleTaken then
			pdata.rootNPC = v
			pdata.onPole = true
			pdata.poleX = v.x + v.width * 0.5
			pdata.poleY = v.y + v.height * 0.5
			pdata.prevPoleX = pdata.poleX
			pdata.prevPoleY = pdata.poleY
			pdata.swingSpeed = p.speedX * 2 + 2 * p.direction
			pdata.swingValue = p.x + p.width * 0.5 - pdata.poleX
			if onlinePlayPlayers.canMakeSound(p) then
				SFX.play(74)					-- saw sfx for grabbing since it fits well enough
			end
			p:mem(0x50,FIELD_BOOL,false)	-- stop spinjumping
		end
	end
end

function swingingPoles.onTick()

	for _,p in ipairs(Player.get()) do
	
		if not p.data.swingingPoles then	-- initializes all the data, for all players.
			p.data.swingingPoles = {
				onPole = false,	-- whether the character is currently swinging on a pole
				poleX = 0,		-- the x position of the pole the player is swinging on
				poleY = 0,		-- the y position of the pole the player is swinging on
				swingSpeed = 0,	-- the speed the player is swinging at.
				noPoleTimer = 0,	-- a timer that counts down to 0. If > 0, the player will not be able to grab on to poles
				isFast = false,	-- whether the player is currently running fast due to getting launched
				rootNPC = nil, 	-- the npc that the player hangs on. Used to allow for moving poles and other stuff. If not given, the system doesn't break
				
				posOffsetX = 0,
				posOffsetY = 0,
				swingValue = 0,
				setX = 0, 	-- x pos of the camera
				setY = 0,	-- y pos of the camera
				rotation = 0,	-- player rotation when on a pole
				frame = 0,		-- player frame (depending on speed, they have a different frame)
				movementDirection = 0,	-- the direction the player will be launched in when jumping off
				LaunchDirectionY = 0,	-- whether the player is launched upwards or downwards
				effecttimer = 0,		-- a timer for the high speed effect

				extraSpeedX = 0,		-- extra speed when the pole itself is moving
				extraSpeedY = 0,
				prevPoleX = 0,
				prevPoleY = 0,
			}
		end
		
		local data = p.data.swingingPoles
		
		if data.onPole then
			--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
				--swingCommand:send(0,p.idx)
			--end
			
			swingingPoles.onPoleBehaviour(p)
			
		end
		
		if data.noPoleTimer > 0 then		-- counts down the timer
			data.noPoleTimer = data.noPoleTimer - 1
		end
		
		if data.isFast then
			p.speedX = p.speedX - 0.025 * p.speedX	-- gradually lose speed
			ultimateSlip(p)							-- be able to be faster than base running speed
			if math.abs(p:mem(0x138, FIELD_FLOAT)) <= 6 or isOnGroundRedigit(p) or p:isClimbing() then
				-- stop being quick and thus slippery
				data.isFast = false
			end
		end
		
	end
end

function swingingPoles.onDraw()
	for _,p in ipairs(Player.get()) do
		local data = p.data.swingingPoles
		if not data then return end
		if data.onPole then
			local playerSpritesheet, spriteData = getPlayerSprites(p)	-- get info I want
			p:setFrame(-50) -- make the player invisible so I can draw them myself!
			
			local transparency = 1
			if booMushroom.isActive(p) then	-- if the character is a boo, we need to do some more stuff!
				p.data.booMushroom.restoreFrame = -50 	-- an invisible player is drawn differently, so this is necessary!
				if onlinePlayPlayers.ownsPlayer(p) then
					transparency = 0.6	-- boo transparency
				else				
					transparency = 0	-- invisible for others
				end
			end
			if not p:mem(0x142,FIELD_BOOL) then	-- only if not blinking
				Graphics.drawBox{			-- you won't believe how often I've copied this and changed it afterwards
					texture      = playerSpritesheet,
					sceneCoords  = true,
					x            = p.x + (p.width / 2),
					y            = p.y + (p.height/ 2),
					width        = 100 * spriteData.direction,
					height       = 100,
					sourceX      = (spriteData.frameX) * 100 / spriteData.scale - spriteData.offsetX, -- p.width * 1.5,
					sourceY      = (spriteData.frameY) * 100 / spriteData.scale - spriteData.offsetY, -- p.width - 4,
					sourceWidth  = 100 / spriteData.scale,
					sourceHeight = 100 / spriteData.scale,
					centered     = true,
					priority     = -25,
					color        = Color.white .. transparency,
					rotation     = data.rotation,
					shader = (p.hasStarman and starShader) or nil,
					uniforms = (p.hasStarman and {time = lunatime.tick() * 2}) or nil,
				}
			end
		end
	end
end

function swingingPoles.onNPCKill(event,killedNPC,harmType)	-- ya can't grab a pole that doesn't exist
	for _,p in ipairs(Player.get()) do
		local data = p.data.swingingPoles
		if killedNPC == data.rootNPC then
			data.rootNPC = nil
			--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
				--dropOffCommand:send(0,p.idx)
			--end
			swingingPoles.dropOff(p)
		end
	end
end

function swingingPoles.onCameraUpdate(idx)		-- makes it so the camera doesn't move when on a pole.
	for _,p in ipairs(Player.get()) do
		local data = p.data.swingingPoles
		local cam = activeCam(p)
		local cam2 = {isSplit = false}
		if camera2 then
			cam2 = camera2
		end
		if data.onPole and (not player2 or camera.isSplit or cam2.isSplit) and onlinePlayPlayers.ownsPlayer(p) then

			cam.x = data.setX
			cam.y = data.setY
		else
			data.setX = cam.x
			data.setY = cam.y
		end
	end
end



return swingingPoles