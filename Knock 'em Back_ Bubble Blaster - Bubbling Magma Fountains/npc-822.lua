--[[
	This template can be used to make your own custom NPCs!
	Copy it over into your level or episode folder and rename it to use an ID between 751 and 1000. For example: npc-751.lua
	Please pay attention to the comments (lines with --) when making changes. They contain useful information!
	Refer to the end of onTickNPC to see how to stop the NPC talking to you.
]]


--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 128,
	gfxheight = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 32,
	--Frameloop-related
	frames = 3,
	framestyle = 0,
	framespeed = 6, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 1,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = true, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = false,
	noyoshi= false, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 1, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,
	
	-- Various interactions
	ishot = true,
	-- iscold = true,
	-- durability = -1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability
	-- weight = 2,
	-- isstationary = true, -- gradually slows down the NPC
	-- nogliding = true, -- The NPC ignores gliding blocks (1f0)

	--Emits light if the Darkness feature is active:
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]=npcID,
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function effectconfig.onTick.TICK_BUBBLE_BURST(v)
	if v.animationFrame < 3 then
		v.framespeed = 2
	elseif v.animationFrame < 7 and v.animationFrame >= 3 then
		v.framespeed = 3
	elseif v.animationFrame == 7 then
		v.framespeed = 4
	elseif v.animationFrame == 8 or v.animationFrame == 9 then
		v.framespeed = 5
	else
		v.framespeed = 6
	end
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	--local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.initializeTimer = 10
		data.timer = 25
		data.speed = math.abs(v.speedX)
		data.maxSpeed = math.abs(v.speedX)
		data.degrade = 0
		data.unslow = data.unslow or false
		v.direction = v.direction or v.spawnDirection
		data.owner = data.owner or nil
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		-- Handling of those special states. Most NPCs want to not execute their main code when held/coming out of a block/etc.
		-- If that applies to your NPC, simply return here.
		-- return
	end
	-- Put main AI below here
	-- Code that makes the NPC friendly and makes it talk. This is a test for verifying that your code runs.
	-- NOTE: If you have no code to put here, comment out the registerEvent line for onTickNPC.

	-- NPC killer
	v.isProjectile = false
	

	-- It'll be bouncy!
	--Push the player if it touches them
	for _, p in ipairs(Player.get()) do
		if Colliders.collide(v, p) and p.deathTimer <= 0 and p ~= data.owner then
			p.speedY = -5
			--SFX.play(Misc.resolveFile("bubblePop.wav"))
			SFX.play(Misc.resolveSoundFile("bumper"))
			p.speedX = p.speedX + 1*v.direction
			p:mem(0x138,FIELD_FLOAT,1*v.direction)
			--v:kill(9)
			--Effect.spawn(npcID, v.x - 32, v.y - 32, plr.section, true)
		end
	
		for _,n in NPC.iterateIntersecting(v.x,v.y,v.x+v.width,v.y+v.height) do
			if Colliders.speedCollide(v,n) and NPC.HITTABLE_MAP[n.id] and n ~= v then
				n.speedY = -5
				SFX.play(Misc.resolveSoundFile("bumper"))
				n.speedX = n.speedX + 5*v.direction
				n.direction = v.direction
				n:mem(0x5C,FIELD_FLOAT,5*v.direction)
			end
		end
	
		for _,b in Block.iterateIntersecting(v.x,v.y,v.x+v.width,v.y+v.height) do
			if Colliders.collide(v,b) and (Block.HURT_MAP[b.id] or Block.LAVA_MAP[b.id])then
				v:kill(9) Effect.spawn(npcID, v.x - 32, v.y - 32, p.section, true) SFX.play(Misc.resolveFile("bubblePop.wav"))
			end
		end
	end

	-- Speed management
	if math.floor(data.speed) == 0 then
		data.speed = 0
	else
		if math.abs(v.speedX) <= 6 then
			data.speed = data.speed - 0.15
		else
			data.speed = data.speed - 0.2
		end
	end

	if math.floor(v.speedX) ~= 0 then
		if data.unslow == false then
			v.speedX = v.direction * data.speed
		else
			v.speedX = v.direction * data.maxSpeed
		end
	end
	
	if math.floor(v.speedY) ~= 0 then
		if data.unslow == false then
			if v.speedY > 0 then v.speedY = v.speedY - 0.05
			elseif v.speedY < 0 then v.speedY = v.speedY + 0.05 end
		end
	else
		v.speedY = 0
	end

	-- If colliding with a wall, the fireball stops moving.
	if v.collidesBlockLeft or v.collidesBlockRight then v.speedX = 0 end
	
	if not v.collidesBlockLeft and not v.collidesBlockRight then
   		v:mem(0x120,FIELD_BOOL,false)
	end

	-- Fade out the fireball
	for _, p in ipairs(Player.get()) do
		if data.degrade >= 2 and data.unslow == false then
			if data.timer > 0 then
				data.timer = data.timer - 1
			else
				v:kill(9) Effect.spawn(npcID+1, v.x-8, v.y-8, p.section, true)
			end
		end
	end

	if data.speed > data.maxSpeed * 0.75 then data.degrade = 0
	elseif data.speed <= data.maxSpeed * 0.75 and data.speed > data.maxSpeed * 0.5 then data.degrade = 2
	elseif data.speed <= data.maxSpeed * 0.5 and data.speed > data.maxSpeed * 0.25 then data.degrade = 4 end

	-- Manage animation
	if data.initializeTimer > 0 then data.initializeTimer = data.initializeTimer - 1 end

	if data.initializeTimer == 0 then
		v.animationFrame = ((lunatime.tick()/config.framespeed) % (config.frames))
	else
		if data.initializeTimer >= 5 then
			v.animationFrame = 3
		else
			v.animationFrame = 4
		end
	end
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			timer = data.timer,
			speed = data.speed,
			maxSpeed = data.maxSpeed,
			degrade = data.degrade,
			unslow = data.unslow,
			--owner = data.owner,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		data.timer = receivedData.timer
		data.speed = receivedData.speed
		data.maxSpeed = receivedData.maxSpeed
		data.degrade = receivedData.degrade
		data.unslow = receivedData.unslow
		--data.owner = receivedData.owner
	end,
}

--Gotta return the library table!
return sampleNPC