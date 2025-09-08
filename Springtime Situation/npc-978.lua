--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 124,
	gfxheight = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 16,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 6,
	framestyle = 0,
	framespeed = 8, -- number of ticks (in-game frames) between animation frame changes

	foreground = false, -- Set to true to cause built-in rendering to render the NPC to Priority -15 rather than -45

	nohurt=true, -- Disables the NPC dealing contact damage to the player
	notcointransformable = true, -- Prevents turning into coins when beating the level
	nofireball = true,
	noiceball = true,
	noyoshi= true, -- If true, Yoshi, Baby Yoshi and Chain Chomp can eat this NPC
	ignorethrownnpcs = true,
	nowaterphysics = true,
	jumphurt = true, --If true, spiny-like (prevents regular jump bounces)
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping and causes a bounce
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false
	nowalldeath = false, -- If true, the NPC will not die when released in a wall
	plantFood = {1, 2, 3, 244, 165, 166, 167, 89, 27, 242, 243, 13, 265, 171, 292, 266, 291, 348, 142, 511, 390, 526, 85, 87, 396, 501, 502, 503, 504, 505, 506, 507, 508, --[[All of these are critter NPCs, you can change what the ids are here]] 1000, 999, 998, 997, 996, 995, 992, 991, 990, 989, 987, 986, 985, 984, 983, 982, 981, 980}
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

local STATE_GROW = 0
local STATE_EAT = 1

function sampleNPC.onTickEndNPC(v)
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
		data.grow = 0
		data.state = STATE_GROW
		data.timer = 0
		data.detectCollider = Colliders.Box(v.x, v.y, 128, 64)
		data.timerDirection = 1
	end
	
	data.detectCollider.x = v.x - 56
	data.detectCollider.y = v.y - v.height

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.isProjectile   --Thrown
	or v.forcedState > 0--Various forced states
	then
		v:kill()
	end
	
	if data.state == STATE_GROW then
		v.animationFrame = math.floor(lunatime.tick() / 8) % 2 + ((v.direction + 1) * sampleNPCSettings.frames / 2)
		if not v.friendly then
			--Hide when a player gets close
			for _,p in ipairs(Player.get()) do
				if math.abs(p.x - v.x) <= 128 and math.abs(p.y - v.y) <= 128 then
					data.grow = math.clamp(data.grow - 2, -64, 0)
				else
					data.grow = math.clamp(data.grow + 2, -64, 0)
				end
			end
		end
		--Eat npcs
		if data.grow == 0 then
			for _,n in ipairs(NPC.get()) do
				for _,e in ipairs(sampleNPCSettings.plantFood) do
					if Colliders.collide(n, data.detectCollider) and n.id ~= v.id and n.id == e then
						data.currentNPC = n
						data.timer = 0
						data.state = STATE_EAT
						if n.x < v.x then v.direction = -1 else v.direction = 1 end
					end
				end
			end
		end
	else
		--Chompy
		data.timer = data.timer + 1 * data.timerDirection
		if data.timer >= 0 and data.timer <= 12 then
			v.animationFrame = math.floor((data.timer - 1 * data.timerDirection) / 3) % 4 + 2 + ((v.direction + 1) * sampleNPCSettings.frames / 2)
			if data.timer == 12 then
				--Kill the targeted NPC
				if data.currentNPC.isValid and Colliders.collide(data.currentNPC, data.detectCollider) then
					data.currentNPC:kill(HARM_TYPE_NPC)
				end
				SFX.play("chomp.wav")
			end
		elseif data.timer > 12 then
			--Hold the bit position for a bit then go back to being idle
			v.animationFrame = 5 + ((v.direction + 1) * sampleNPCSettings.frames / 2)
			if data.timer == 24 then
				data.timer = 11
				data.timerDirection = -1
			end
		else
			--Reset the timer and state
			data.timer = 0
			data.state = STATE_GROW
			data.timerDirection = 1
		end
	end
end

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.CENTER
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.CENTER
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.grow then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety - data.grow / 2,
		width = config.gfxwidth + data.grow * 2,height = config.gfxheight + data.grow,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return sampleNPC