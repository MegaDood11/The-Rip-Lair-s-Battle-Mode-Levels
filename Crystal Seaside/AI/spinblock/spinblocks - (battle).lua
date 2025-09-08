--[[
	spinblocks.lua v1.0 - by "Master" of Disaster
	
	Spin blocks from NSMB, jump on it, and get launched high into the sky!!
	This version is made specifically for MDA's battle episode. Drilling on other players harms those!
	
	Credit or I'll ask the mods to spin your head around like crazy and make you dizzy or something
]]--

local spinblocks = {
	spinGrav = 0.15,					-- gravity the player has while spinning; lower gravity means higher bounces!
	terminalVelocity = 3,			-- max falling speed the player can fall at
	speedCap = 4,					-- max horizontal speed the player can have when gliding
	accelerationDecrease = 0.005,	-- subtracted from the player speed when trying to accelerate; 0.1 is Mario's default acceleration in air before reaching walking speed cap, then 0.5
	actAsSpinjump = true,			-- if false, the player will not actually be spinjumping
	canDrill = true,				-- if true, you can press down to start drilling downwards
	canCancelDrill = false,			-- if true, you stop drilling when stopping to hold down
	drillAccel = 0.8,				-- how much downwards speed a player gains per frame when drilling
	launchSFX = 24,					-- the sfx that plays when getting yeeted
	
	colliderHeight = 96,			-- for testing purposes. Height of the collider that harms other players. Needs to be unreasonably big apparently
}

spinblocks.bannedNPCs = {	-- list of all npc ids for npcs the player should not be able to hold when flying. By default has both grabbable propeller blocks since they enable infinite flight
	278, 279,
}

local onlinePlay = require("scripts/onlinePlay")
local onlinePlayPlayers = require("scripts/onlinePlay_players")
local battlePlayer = require("scripts/battlePlayer")

local npcIDs = {}
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local folderpath = "AI/spinblock/"
local drillsprite = Graphics.loadImageResolved(folderpath .. "drillsprite.png")
local spinjumpframes = {1, 15,-1, 13}

registerEvent(spinblocks, "onTick")
registerEvent(spinblocks, "onDraw")

local checkHarmPlayerCommand = onlinePlay.createCommand("checkHarmPlayerSpinblock",onlinePlay.IMPORTANCE_MAJOR)

local function canFly(p)
	local bdata = battlePlayer.getPlayerData(p)
	local holdingNPCID = 0
	if p.holdingNPC then
		holdingNPCID = p.holdingNPC.id
	end
	return (
		not (p:mem(0x146,FIELD_WORD) == 2) and	-- bottom collision
		not (p.standingNPC)	 and	-- not on an npc (unless getting launched)
		(p:mem(0x48,FIELD_WORD) == 0) and	-- not on a slope
		not p:mem(0x36,FIELD_BOOL)	and			-- not In water
		not p:mem(0x06,FIELD_BOOL)	and			-- not in quicksand
		not (p:mem(0x40,FIELD_WORD) > 0) and	-- not Climbing
		not p:mem(0x44, FIELD_BOOL) and			-- not Riding a rainbow shell
		not p:mem(0x4A, FIELD_BOOL) and			-- not a statue
		not p:mem(0x13C, FIELD_BOOL) and 		-- alive
		p.mount == 0 and						-- not on a Yoshi or Boot
		not p.isMega and						-- not mega
		holdingNPCID ~= 955 and					-- not holding the stone
		p.deathTimer == 0 and					-- still alive
		Level.winState() == 0 and 				-- has not finished the level yet
		bdata.respawnTimer == 0					-- is not currently respawning
	)
end

local function blockFilterSmash(o)
    if not (o.isHidden or Block.SLOPE_MAP[o.id]) then
        return true
    end
end

local function checkHarmPlayer(p)	-- checks whether the player can harm another player and does so
	local data = p.data.spinblocks
	
	data.drillCollider.x = p.x + p.speedX	-- collider should be in the proper place
	data.drillCollider.y = p.y + p.height + p.speedY
	
	for _, p2 in ipairs(Player.get()) do	-- hurt players heheheheheheherharharharhahrahrhrhghrhrhrhghrhrh
		if Colliders.collide(data.drillCollider,p2) and p ~= p2 and battlePlayer.getPlayerData(p2).respawnTimer == 0 then	-- only bounce off of other players that are alive
			p2:harm()
			if onlinePlayPlayers.canMakeSound(p) then
				SFX.play(2)
			end
			p.speedY = -8
		end
	end
end

function checkHarmPlayerCommand.onReceive(sourcePlayerIdx, playerIdx)
    local p = Player(playerIdx)

    checkHarmPlayer(p)
end

local function launchUp(v)	-- launches up all players that are on top of the spin block
	for _,p in ipairs(Player.get()) do	-- check whether a player is on top of the thing
		if Colliders.collide(p,v.data.collider) then
			p.y = p.y - 10
			p.x = - p.width * 0.5 + v.x + v.width * 0.5
			p.speedX = 0
			--p.speedY = -20
			if onlinePlayPlayers.canMakeSound(p) then
				SFX.play(spinblocks.launchSFX)
			end
			p.data.spinblocks.launchSpeed = -v.data._settings.launchSpeed	-- has to be applied next frame because standing npcs are mean
			p.data.spinblocks.isFlying = true
		end
	end
end

function spinblocks.register(id)
	--npcManager.registerEvent(id, spinblocks, "onTickEndNPC")
	npcManager.registerEvent(id, spinblocks, "onTickNPC")
	npcManager.registerEvent(id, spinblocks, "onDrawNPC")
	--registerEvent(spinblocks, "onNPCHarm")
	npcIDs[id] = true
end

function spinblocks.onTick()
	for _,p in ipairs(Player.get()) do	-- check whether a player is on top of the thing
		if not p.data.spinblocks then
			p.data.spinblocks = {
				isFlying = false,	-- true if the player is gently spinning downwards
				launchSpeed = 0,
				isDrilling = false,
				drillCollider = Colliders.Box(p.x,p.y + p.height, p.width, spinblocks.colliderHeight),
				drillframe = 0,	-- animation frame of the shock effect
				drillTimer = 0,	-- animation timer for this ^
			}
		end
		local data = p.data.spinblocks

		-- launch off
		if data.launchSpeed ~= 0 then
			p:mem(0x11C,FIELD_WORD,0)		-- no jump speed
			p:mem(0x11E,FIELD_BOOL,false)	-- no jump press
			p:mem(0x120,FIELD_BOOL,false)	-- no spinjump press
			if spinblocks.actAsSpinjump then
				p:mem(0x50,FIELD_BOOL,true)		-- yes spinjump
			end
			p.speedY = data.launchSpeed
			data.launchSpeed = 0
		end
		
		if data.isFlying then
			if p.forcedState ~= FORCEDSTATE_NONE then return end	-- no gliding while lagging
			
			if p.holdingNPC then	-- if the player is holding a banned npc, release run so they throw it away
				if table.contains(spinblocks.bannedNPCs, p.holdingNPC.id) then
					p.keys.run = false
				end
			end
			
			if not data.isDrilling then		-- low gravity when not drilling or lagging (if the latter was, you'd gain height by getting hit)
				p.speedY = math.min(spinblocks.terminalVelocity,p.speedY - (Defines.player_grav - spinblocks.spinGrav))
			end
			p:mem(0x160,FIELD_WORD,30)	-- no projectiles
			p:mem(0x162,FIELD_WORD,30)	-- no secondary projectiles
			
			if p.keys.right and p.speedX >= spinblocks.speedCap then	-- don't get faster than the speed cap
				p.speedX = spinblocks.speedCap
			elseif p.keys.left and p.speedX <= -spinblocks.speedCap then
				p.speedX = - spinblocks.speedCap
			end
			
			if p.keys.right then		-- give the player a lower acceleration while gliding
				p.speedX = p.speedX - spinblocks.accelerationDecrease
			elseif p.keys.left then
				p.speedX = p.speedX + spinblocks.accelerationDecrease
			end
			
			if p.keys.down and spinblocks.canDrill and not data.isDrilling and p.speedY > 0 then		-- start drilling
				data.isDrilling = true
			elseif ((p.keys.down == KEYS_UP and spinblocks.canCancelDrill) or (p.speedY < 0)) and data.isDrilling then	-- cancel drillling (if you can)
				data.isDrilling = false
			end
			
			if not spinblocks.actAsSpinjump then	-- still do the spinning animation, despite not being a spinjump technically
				p:playAnim(spinjumpframes,2,false,10)
				p.keys.down = false	-- no ducking
			end
			
			if data.isDrilling then	-- drilling code
			
				if p.powerup == 4 or p.powerup == 5 then	-- no slow descend when drilling please
					p.keys.jump = false
					p.keys.altJump = false
				end
				-- and then fate said "wouldn't it be funny if you made another ground pound like drill move?"
				p.speedY = p.speedY + spinblocks.drillAccel	-- accelerate the player downwards
				
				if not spinblocks.canCancelDrill and spinblocks.actAsSpinjump then	-- always hold down when drilling if you can't cancel; that way you always tear down through enemies with a spin jump
					p.keys.down = true
				end
				
				data.drillCollider.x = p.x + p.speedX	-- collider should be in the proper place
				data.drillCollider.y = p.y + p.height + p.speedY
				
				for c, n in ipairs(Colliders.getColliding{a = data.drillCollider, btype = Colliders.BLOCK, filter = blockFilterSmash}) do		-- A collider that breaks blocks!
					if Block.MEGA_SMASH_MAP[n.id] and n.contentID == 0 then	-- only destroy blocks without something in them
						n:remove(true)
					end
					n:hit(2)	-- hit blocks otherwise
				end
				
				if onlinePlayPlayers.ownsPlayer(p) then	-- hit others. Synced
					if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
						checkHarmPlayerCommand:send(0,p.idx)
					end
					checkHarmPlayer(p)
				end
				
				if data.drillTimer < 4 then	-- animate the drill animation
					data.drillTimer = data.drillTimer + 1
				else
					data.drillTimer = 0
					data.drillframe = data.drillframe + 1
					if data.drillframe >= 3 then
						data.drillframe = 0
					end
				end
			end
			
			
			if not canFly(p) then	-- stop flying when you can't anymore
				data.isFlying = false
				data.isDrilling = false
			end
		end
	end
end

function spinblocks.onTickNPC(v)

	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
	
	if not data.initialized then	-- initializes all necessary data
		data.bottomFrame = 0
		data.topFrame = 0
		data.extraHeight = 16
		data.animSpeed = 4
		data.extraAnimSpeed = 0
		data.collider = Colliders.Box(v.x,v.y - 16,v.width,16)
		
		data.bottomAnimTimer = 0
		data.topAnimTimer = 0
	
		data.initialized = true
	end
	npcutils.applyLayerMovement(v)
	data.collider.x = v.x
	data.collider.y = v.y - 16
	
	data.extraHeight = 16
	data.extraAnimSpeed = 0
	for _,p in ipairs(Player.get()) do	-- check whether a player is on top of the thing
		if Colliders.collide(p,data.collider) then
			data.extraHeight = 0		-- press platform in
			data.extraAnimSpeed = 10
			
			if not (p.keys.left or p.keys.right) then	-- move the player to the middle and rotate them
				local distance = p.x + p.width * 0.5 - v.x - v.width * 0.5
				if math.abs(distance) <= 3 then
					p.x = v.x + v.width * 0.5 - p.width * 0.5
				else
					p.x = p.x - distance * 0.1 - math.sign(distance) * 1
				end
				
				if not p.keys.down then		-- spinning animation when not ducking
					p:playAnim(spinjumpframes,3,false,10)
				end
			end
			

			
			
			if p.keys.jump == KEYS_PRESSED or p.keys.altJump == KEYS_PRESSED then	-- launch players up
				launchUp(v)
			end
		end
	end
	
	
	
	-- animate the bottom and top segment
	data.bottomAnimTimer = data.bottomAnimTimer + data.animSpeed
	data.topAnimTimer = data.topAnimTimer + data.animSpeed + data.extraAnimSpeed
	if data.bottomAnimTimer >= 10 then
		data.bottomAnimTimer = 0
		data.bottomFrame = data.bottomFrame + 1
		if data.bottomFrame >= 16 then
			data.bottomFrame = 0
		end
	end
	while data.topAnimTimer >= 10 do
		data.topAnimTimer = data.topAnimTimer - 10
		data.topFrame = data.topFrame + 1
		if data.topFrame >= 16 then
			data.topFrame = 0
		end
	end
end

function spinblocks.onDraw()
	for _,p in ipairs(Player.get()) do
		local bdata = battlePlayer.getPlayerData(p)
		local data = p.data.spinblocks
		if data.isDrilling and data.isFlying and bdata.respawnTimer == 0 then
			Graphics.drawBox{							-- rapidly approaching earth's core
				texture      = drillsprite,
				sceneCoords  = true,
				x            = p.x + (p.width / 2),
				y            = p.y + (p.height) - 10,
				width        = 92,
				height       = 58,
				sourceX      = 0,
				sourceY      = 58 * data.drillframe,
				sourceWidth  = 92,
				sourceHeight = 58,
				centered     = true,
				priority     = -24,
				color        = Color.white .. 0.8,
				rotation     = 0,
			}
		end
	end
end


function spinblocks.onDrawNPC(v)
	local data = v.data
	if (data.bottomFrame) and (not v.isHidden) and (v.isValid) then
		local topSprite = Graphics.loadImageResolved(folderpath .. "npc-" .. v.id .. "-top.png")
		local bottomSprite = Graphics.loadImageResolved(folderpath .. "npc-" .. v.id .. "-bottom.png")
		
		Graphics.drawBox{			-- draws the bottom segment that steadily rotates.
			texture      = bottomSprite,
			sceneCoords  = true,
			x            = v.x + (v.width / 2),
			y            = v.y + v.height - 16,
			width        = v.width,
			height       = 32,
			sourceX      = 0,
			sourceY      = 32 * data.bottomFrame,
			sourceWidth  = v.width,
			sourceHeight = 32,
			centered     = true,
			priority     = -45,
			color        = Color.white .. 1,
			rotation     = 0,
		}
		
		Graphics.drawBox{			-- draws the top segment that can be pressed in and rotates in that case.
			texture      = topSprite,
			sceneCoords  = true,
			x            = v.x + (v.width / 2),
			y            = v.y + 16 - data.extraHeight,
			width        = v.width,
			height       = 32,
			sourceX      = 0,
			sourceY      = 32 * data.topFrame,
			sourceWidth  = v.width,
			sourceHeight = 32,
			centered     = true,
			priority     = -46,
			color        = Color.white .. 1,
			rotation     = 0,
		}
	end
end

return spinblocks