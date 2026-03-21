--[[
	This template can be used to make your own custom NPCs!
	Copy it over into your level or episode folder and rename it to use an ID between 751 and 1000. For example: npc-751.lua
	Please pay attention to the comments (lines with --) when making changes. They contain useful information!
	Refer to the end of onTickNPC to see how to stop the NPC talking to you.
]]


--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")
local battlePlayer = require("scripts/battlePlayer")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,

	-- ANIMATION
	--Sprite size
	gfxwidth = 32,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 16,
	height = 16,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 8,
	--Frameloop-related
	frames = 6,
	framestyle = 1,
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
	noblockcollision = false,
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
	lightradius = 48,
	lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	lightcolor = Color.white,

	--Define custom properties below
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
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
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

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
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
		data.timer = 25
		data.speed = math.abs(v.speedX)
		data.maxSpeed = math.abs(v.speedX)
		data.degrade = 0
		v.direction = v.direction or v.spawnDirection
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
	
	for _,n in NPC.iterateIntersecting(v.x,v.y,v.x+v.width,v.y+v.height) do
		if Colliders.speedCollide(v,n) and NPC.HITTABLE_MAP[n.id] and NPC.config[n.id].ishot == false then
			n:harm(3)
		end
	end
	
	v:mem(0x132,FIELD_WORD, data.culprit)
	
	for _,p in ipairs(Player.get()) do
		if p.idx ~= v:mem(0x132,FIELD_WORD) and Colliders.collide(v,p) then
			battlePlayer.harmPlayer(p,1)
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
		v.speedX = v.direction * data.speed
	end

	if math.floor(v.speedY) ~= 0 then
		if v.speedY > 0 then v.speedY = v.speedY - 0.05
		elseif v.speedY < 0 then v.speedY = v.speedY + 0.05 end
	else
		v.speedY = 0
	end

	-- If colliding with a wall, the fireball stops moving.
	if v.collidesBlockLeft or v.collidesBlockRight then v.speedX = 0 end
	
	if not v.collidesBlockLeft and not v.collidesBlockRight then
   		v:mem(0x120,FIELD_BOOL,false)
	end

	-- Fade out the fireball
	if data.degrade >= 2 then
		if data.timer > 0 then data.timer = data.timer - 1 else v:kill(9) end
	end

	if data.speed > data.maxSpeed * 0.75 then data.degrade = 0
	elseif data.speed <= data.maxSpeed * 0.75 and data.speed > data.maxSpeed * 0.5 then data.degrade = 2
	elseif data.speed <= data.maxSpeed * 0.5 and data.speed > data.maxSpeed * 0.25 then data.degrade = 4 end

	-- Manage animation
	v.animationFrame = ((lunatime.tick()/config.framespeed) % (config.frames/3)) + data.degrade + (((v.direction+1)/2) * config.frames)
end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			speed = data.speed,
			timer = data.timer,
			maxSpeed = data.maxSpeed,
			degrade = data.degrade,
			culprit = data.culprit,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.speed = receivedData.speed
		data.timer = receivedData.timer
		data.maxSpeed = receivedData.maxSpeed
		data.degrade = receivedData.degrade
		data.culprit = receivedData.culprit
	end,
}

--Gotta return the library table!
return sampleNPC