--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local piano = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local pianoSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 124,
	gfxwidth = 144,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 108,
	height = 78,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 16,
	--Frameloop-related
	frames = 7,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	turninterval = 120,
}

local STATE_SIT = 0
local STATE_ATTACK = 1

--Applies NPC settings
npcManager.setNpcSettings(pianoSettings)

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

--Register events
function piano.onInitAPI()
	npcManager.registerEvent(npcID, piano, "onTickEndNPC")
end

local sound = Misc.resolveFile("Madpiano_bite.ogg")

function piano.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	--Collider to activate the npc
	local searchBox = Colliders.Box(v.x - (v.width * 1), v.y - (v.height * 1), v.width * 2, v.height * 2)
	searchBox.x = v.x - v.width / 2
	searchBox.y = v.y - v.height / 2
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.state = STATE_SIT
		data.timer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_SIT
		data.timer = data.timer or 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_ATTACK
	end

	if data.state == STATE_SIT then
		v.animationFrame = 0
		data.timer = 0
		v.speedX = 0
		v.friendly = true
		
		--If the player comes close
		if Colliders.collide(plr,searchBox) then
			data.state = STATE_ATTACK
			SFX.play(sound)
			npcutils.faceNearestPlayer(v)
			v.speedY = -3
		end
		
	else
		data.timer = data.timer + 1
		v.animationFrame = math.floor(data.timer / 5) % (pianoSettings.frames - 1) + 1
		v.speedX = 2 * v.direction
		v.friendly = false
		v.ai1 = v.ai1 + 1
		if data.timer % 30 == 0 then
			SFX.play(sound)
			if v.collidesBlockBottom then
				v.speedY = -3
			end
		end
		if v.ai1 == pianoSettings.turninterval then
			--Chase the player
			if v.x > plr.x then
				v.direction = -1
			else
				v.direction = 1
			end
			v.ai1 = 0
		end
		if plr.x <= v.x + 240 and plr.x >= v.x - 160 then
			v.ai2 = 0
		else
			v.ai2 = v.ai2 + 1
			if v.ai2 >= 96 then
				data.state = STATE_SIT
				v.ai1 = 0
				v.ai2 = 0
			end
		end
	end	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = pianoSettings.frames
	});
	
end

--Gotta return the library table!
return piano