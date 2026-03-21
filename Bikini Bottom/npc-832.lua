--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 128,
	gfxheight = 96,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 96,
	height = 64,
	frames = 2,
	framestyle = 1,
	framespeed = 4, -- number of ticks (in-game frames) between animation frame changes

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	nogravity = false,
	noblockcollision = false,
	notcointransformable = false, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,
	
	--Various interactions
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function sampleNPC.onTickNPC(v)
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
		--Initialize necessary data.
		data.initialized = true
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
	
	v.speedX = 2 * v.direction
	if lunatime.tick() % 4 == 0 then
		local e = Effect.spawn(npcID, v.x + 112 - ((v.direction + 1) * 64), v.y + 12 + v.height * 0.5)
		e.speedX = RNG.random(2, 3) * -v.direction
		e.speedY = RNG.random(-3,-5)
	end
	
	v.despawnTimer = 180
	
	for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
		if p.forcedState == 0 and p.deathTimer <= 0 then
			p:mem(0x3C, FIELD_BOOL, true)
			p.speedX = 10 * v.direction
			p.speedY = -12
			SFX.play("cartoon-boing.mp3")
			p.data.spongeBobLevelLockControls = 64
			p.data.spongeBobLevelLockControlsDir = v.direction
		end
	end
	
	for _,p in ipairs(Player.get()) do
		if not p.data.spongeBobLevelLockControls then return end
		p.data.spongeBobLevelLockControls = p.data.spongeBobLevelLockControls - 1
		p.keys.left = KEYS_UP
		p.keys.right = KEYS_UP
		p.keys.jump = KEYS_UP
		p.keys.altJump = KEYS_UP
		p.keys.run = KEYS_UP
		p:mem(0x154, FIELD_WORD, false)
		if p.data.spongeBobLevelLockControls <= 0 then p.data.spongeBobLevelLockControls = nil p.data.spongeBobLevelLockControlsDir = nil end
	end
end

--Gotta return the library table!
return sampleNPC