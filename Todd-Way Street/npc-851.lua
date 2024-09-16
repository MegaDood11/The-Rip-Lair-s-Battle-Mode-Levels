--[[
	This template can be used to make your own custom NPCs!
	Copy it over into your level or episode folder and rename it to use an ID between 751 and 1000. For example: npc-751.lua
	Please pay attention to the comments (lines with --) when making changes. They contain useful information!
	Refer to the end of onTickNPC to see how to stop the NPC talking to you.
]]


--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local onlinePlay = require("scripts/onlinePlay")
local battlePlayer = require("scripts/battlePlayer")
local annihilatePlayerCommand = onlinePlay.createCommand("annihilatePlayer",onlinePlay.IMPORTANCE_MAJOR)

local startingDirection = RNG.irandomEntry{-1,1}
local driveTimer = 450
local cooldown = 650
local vroomSFX = nil
local hitPlayers = {}

local driveLength = 415


--Create the library table
local killerTaxi = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local killerTaxiSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 256,
	gfxheight = 128,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 128,
	height = 80,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 2,
	framestyle = 1,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	-- LOGIC
	--Movement speed. Only affects speedX by default.
	speed = 9,
	luahandlesspeed = true, -- If set to true, the speed config can be manually re-implemented
	nowaterphysics = false,
	cliffturn = false, -- Makes the NPC turn on ledges
	staticdirection = false, -- If set to true, built-in logic no longer changes the NPC's direction, and the direction has to be changed manually

	--Collision-related
	npcblock = false, -- The NPC has a solid block for collision handling with other NPCs.
	npcblocktop = false, -- The NPC has a semisolid block for collision handling. Overrides npcblock's side and bottom solidity if both are set.
	playerblock = false, -- The NPC prevents players from passing through.
	playerblocktop = false, -- The player can walk on the NPC.

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC

	score = 9, -- Score granted when killed
	--  1 = 10,    2 = 100,    3 = 200,  4 = 400,  5 = 800,
	--  6 = 1000,  7 = 2000,   8 = 4000, 9 = 8000, 10 = 1up,
	-- 11 = 2up,  12 = 3up,  13+ = 5-up, 0 = 0

	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
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
	-- ishot = true,
	-- iscold = true,
	-- durability = -1, -- Durability for elemental interactions like ishot and iscold. -1 = infinite durability
	-- weight = 2,
	-- isstationary = true, -- gradually slows down the NPC
	-- nogliding = true, -- The NPC ignores gliding blocks (1f0)

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(killerTaxiSettings)

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
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local function roadkillPlayer(p)
	--p.forcedState = 0
	--p.powerup = 1
	--p:harm()
	p.keys.run = KEYS_UP
	p.keys.altRun = KEYS_UP
	p:mem(0x154,FIELD_WORD,0)
	p:mem(0x11C,FIELD_WORD,0)
	
	p.speedX = 12 * startingDirection --RNG.irandomEntry{-1,1}
	p.speedY = -12
	p:mem(0x3C,FIELD_BOOL,true)
	hitPlayers[p.idx] = true
	--end
	local thud = SFX.create{
		x = p.x + p.width*0.5,
		y = p.y + p.height*0.5,
		falloffRadius = 2560,
		sound = Misc.resolveFile("Todd-Way Street/thud.ogg"),
		parent = p,
		source = SFX.SOURCE_CIRCLE,
		sourceRadius = 2560,
		volume = 0.75,
		play = true,
		loops = 1,
	}
	--battlePlayer.harmPlayer(p, battlePlayer.HARM_TYPE.NORMAL)
	--p:mem(0x140,FIELD_WORD,1)
end


function annihilatePlayerCommand.onReceive(sourcePlayerIdx, playerIdx)
	local p = Player(playerIdx)
	roadkillPlayer(p)
end


--Register events
function killerTaxi.onInitAPI()
	registerEvent(killerTaxi,"onTick")
	npcManager.registerEvent(npcID, killerTaxi, "onTickNPC")
	--npcManager.registerEvent(npcID, killerTaxi, "onDrawNPC")
end

function killerTaxi.onTick()
	for i,p in ipairs(Player.get()) do
		if hitPlayers[p.idx] then
			p.keys.left = KEYS_UP
			p.keys.right = KEYS_UP
			p.keys.jump = KEYS_UP
			p.keys.altJump = KEYS_UP
			if p:isGroundTouching() or p.speedY == 0 then
				hitPlayers[p.idx] = nil
				p:harm()
			end
		end
	end
end


function killerTaxi.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--v.direction = startingDirection
		startingDirection = v.direction
		if onlinePlay.currentMode == onlinePlay.MODE_OFFLINE and battlePlayer.getActivePlayerCount() > 1 then
			driveLength = 429
			--SFX.play(12)
		end
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		return
	end
	
	local config = NPC.config[npcID]

	if driveTimer < driveLength then
		v.speedX = config.speed * v.direction
	elseif driveTimer >= driveLength and driveTimer < 450 then
		v.speedX = v.speedX * 0.85
		--v.x = math.lerp(v.x,v.spawnX,0.075)
	elseif v.speedX ~= 0 then
		cooldown = 650
		v.speedX = 0
		v.x = v.spawnX
	end
	v.despawnTimer = 180
	cooldown = math.max(cooldown - 1, 0)
	if cooldown <= 0 and driveTimer >= 450 then
		--SFX.play("Todd-Way Street/vroom.ogg")
		vroomSFX = SFX.create{
			x = v.x + v.width*0.5,
			y = v.y + v.height*0.5,
			falloffRadius = 2560,
			sound = Misc.resolveFile("Todd-Way Street/vroom.ogg"),
			parent = v,
			source = SFX.SOURCE_CIRCLE,
			sourceRadius = 2560,
			volume = 2,
			play = true,
			loops = 1,
		}
		driveTimer = 0
	elseif cooldown == 65 then
		SFX.play("Todd-Way Street/honk-honk.ogg",5)
	end
	if cooldown > 65 then
		local anim = 0
		if v.direction == 1 and config.framestyle == 1 then
			anim = anim + config.frames
		end
		v.animationFrame = anim
		v.animationTimer = 0
	end
	
	driveTimer = driveTimer + 1
	
	if cooldown > 0 then return end
	
	if math.abs(v.speedX) < 2 then return end
	if lunatime.tick() % 12 == 0 then
		local edge = v.x - 64
		if v.direction == -1 then
			edge = v.x + v.width + 64
		end
		local e = Effect.spawn(10,edge,v.y + v.height*0.5)
		e.x = e.x - e.width*0.5
		e.speedX = 1 * v.direction
		e.speedY = RNG.randomInt(-3,1)
	end
	local leftOffset = math.min(v.speedX,0)
	local rightOffset = math.max(v.speedX,0)
	
	-- harming the player who got hit isn't enough, I want them dead on the floor
	for i,p in ipairs(Player.getIntersecting(v.x + leftOffset,v.y - 2,v.x+v.width+rightOffset,v.y+v.height)) do
		if math.abs(v.speedX) > 2 and p.forcedState == 0 
		and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) and not hitPlayers[p.idx]
		and p:mem(0x140,FIELD_WORD) <= 0 and battlePlayer.getPlayerIsActive(p) then
			if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
				annihilatePlayerCommand:send(0,p.idx)
			end
			roadkillPlayer(p)
		end	
	end
end

function killerTaxi.onDrawNPC(v)
	Text.print(driveTimer,100,100)
	Text.print(cooldown,100,120)
	Text.print(v.x,100,130)
end

--Gotta return the library table!
return killerTaxi