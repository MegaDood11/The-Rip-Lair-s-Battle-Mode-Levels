local billy = {}

local npcManager = require("npcManager")

local utils = require("npcs/npcutils")

local onlinePlayNPC = require("scripts/onlinePlay_npc")

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,
	frames=1,
	framestyle=1,
	framespeed=2,
	jumphurt = true,
	nohurt=true,
	grabside = true,
	playerblock=false,
	npcblock=false,
	npcblocktop=false,
	playerblocktop=false,
	harmlessgrab=true,
	harmlessthrown=true,
	ignorethrownnpcs=true,
	nowalldeath=true,
	isstationary=true,
	standsonclowncar = true,
	gfxoffsety=2,
	width=64,
	height=64,
	gfxwidth=64,
	gfxheight=64,

	fueldisplay = true,
	bubblerefill = 1,
	maxbubbles = 3,
	defaultprojectile = npcID+1,

	--Define custom properties below
	shootmode = 1, -- 0: randomized y-speed, 1: straight-line, 2: three-way
	shootspeed = 4, -- Configures shooting speed of the bubble.
	unslowbubble = true, -- If true: prevents the bubble from slowing down and expiring unless if it hits lava or spikes.
	triplelimit = 6, -- A hidden counter that limits how many times the bubbles can shoot as a trio, if shootmode == 2.
}

npcManager.setNpcSettings(sampleNPCSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
	}, 
	{
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

-- * Feel free to use.

local npcID = NPC_ID

local function spawnNPC(id, v, speedX, speedY)
	local n = NPC.spawn(id, v.x, v.y, v.section)
	n:mem(0x136,FIELD_BOOL, true)
	n:mem(0x12E,FIELD_WORD, 9999)
	n:mem(0x130,FIELD_WORD, v:mem(0x12C, FIELD_WORD))
	n:mem(0x132,FIELD_WORD, v:mem(0x12C, FIELD_WORD))
	
	n.y = n.y+v.height*0.5-n.height*0.5

	n.layerName = "Spawned NPCs"
	
	if v.direction == 1 then
		n.x = n.x + 0.5 * v.width
	else
		n.x = n.x - n.width + 0.5 * v.width
	end
	
	n.direction = v.direction
	n.speedX = v.direction*speedX
	n.speedY = speedY
	n.friendly = v.friendly

	if n.id == NPC.config[v.id].defaultprojectile then
		n.data.unslow = NPC.config[v.id].unslowbubble
		n.data.owner = v.heldPlayer
	end
	
	if NPC.config[n.id].iscoin then
		n.ai1 = 1
		n.speedY = RNG.random(-4,0)
	end
	
	return n
end

function billy.onTickNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12A,FIELD_WORD) <= 0 then return end

	local settings = v.data._settings
	local data = v.data
	local config = NPC.config[v.id]

	if not data.initialized then
		data.initialized = true

		data.timer = 0
		data.projectile = settings.projectile
		data.additionalVelocity = 0
		data.inBlock = false
		if data.projectile == 0 then
			data.projectile = config.defaultprojectile
		end

		data.angleSpeedY = 0
		data.fireAngle = 0
		data.count = config.maxbubbles
		data.maxCount = data.count
		data.overuseCount = config.triplelimit
		data.wings = Graphics.loadImageResolved("npc-" .. npcID .. "-wings.png")
		data.wingSpeed = 0
		data.wingPriority = -44

		-- Sprite bar
		data.bar = Sprite.bar{
			x = 0,
			y = 0,
			width = 32,
			height = 8,
			pivot = Sprite.align.TOP,
			value = 1,
		}
		data.barcolor = Color.green

		return
	end

	-- Manage values when held or not held
	if v.heldPlayer then
		if data.count > 0 or data.maxCount < 0 then
			data.wingSpeed = 4
		else
			data.wingSpeed = 12
		end

		data.wingPriority = -24
	else
		--[[if data.overuseCount < config.triplelimit and lunatime.tick() % 16 == 0 then
			data.overuseCount = data.overuseCount + 1
		end]]

		if data.count > 0 or data.maxCount < 0 then
			data.wingSpeed = 8
		else
			data.wingSpeed = 12
		end

		data.wingPriority = -44
	end

	data.inBlock = false

	for _,b in Block.iterateIntersecting(v.x,v.y,v.x+v.width,v.y+v.height) do
		if v.heldPlayer and Colliders.collide(v,b) and Block.SOLID_MAP[b.id] and b.isHidden == false then
			data.inBlock = true
		end
	end

	if v.heldPlayer then
		if (v.heldPlayer.speedX > 0 and v.heldPlayer.direction == DIR_LEFT) or (v.heldPlayer.speedX < 0 and v.heldPlayer.direction == DIR_RIGHT) then
			data.additionalVelocity = 0
		else
			data.additionalVelocity = math.abs(v.heldPlayer.speedX)
		end
	end

	v.ai1 = 0

	if v:mem(0x12C, FIELD_WORD) > 0 then
		data.timer = data.timer + 1
	elseif (v:mem(0x60, FIELD_WORD) > 0 and Player(v:mem(0x60, FIELD_WORD)).keys.run)  then
		data.timer = data.timer + 1
	else
		data.timer = 0
	end

	if (data.timer >= 32--[[settings.timer]]) and data.inBlock == false and (data.count > 0 or data.maxCount <= 0) then
		local id = data.projectile
		if id == 0 then
			id = 17
		end
		-- Determine fire angle

		if config.shootmode == 0 then
			data.angleSpeedY = RNG.random(-3,3)
		else
			data.angleSpeedY = 0
		end

		local n
		if id > 0 then
			if (config.shootmode < 2) then
				n = spawnNPC(id, v, config.shootspeed + data.additionalVelocity,data.angleSpeedY)
			else
				if data.overuseCount > 0 then
					for i = 1,3 do
						local addSpeedY
						if i == 1 then addSpeedY = -config.shootspeed/1.5
						elseif i == 2 then addSpeedY = 0
						elseif i == 3 then addSpeedY = config.shootspeed/1.5 end
						n = spawnNPC(id, v, config.shootspeed + data.additionalVelocity,addSpeedY)
					end
				else
					n = spawnNPC(id, v, config.shootspeed + data.additionalVelocity,data.angleSpeedY)
				end
			end
			data.count = data.count - 1
			if data.overuseCount > 0 then data.overuseCount = data.overuseCount - 1 end
		else
			for i = -1,id,-1 do
				n = spawnNPC(10, v, RNG.random(2, 5))
			end
			data.count = data.count - 1
			if data.overuseCount > 0 then data.overuseCount = data.overuseCount - 1 end
		end
		
		v.ai1 = 0
		data.timer = 0
		
		--local e = Effect.spawn(10, n.x + n.width*0.5, n.y + n.height*0.5)
		--e.x = e.x - e.width*0.5
		--e.y = e.y - e.height*0.5
		SFX.play(Misc.resolveSoundFile("snd_bubblesmall"))
		if data.count == 0 then
			Effect.spawn(131,v.x,v.y+4)
			SFX.play(88)
			v:kill(9)
		end
	end

	-- Refill thanks to underwater
	if data.count > data.maxCount and data.maxCount > 0 then
		data.count = data.maxCount
	end
	
	if v.underwater and data.count < data.maxCount and config.bubblerefill > 0 then
		SFX.play(16)
		data.count = data.count + math.floor(config.bubblerefill)
	end

	if not v.collidesBlockLeft and not v.collidesBlockRight then
   		v:mem(0x120,FIELD_BOOL,false)
	end

	-- Grab from the top code based on summonClosestNPC.lua by MegaDood & MrNameless
	if not v.heldPlayer then
		for _,p in ipairs(Player.get()) do
			if Colliders.collide(p,v) and (p.keys.run or p.keys.altRun) and p.holdingNPC == nil
			and p.character ~= CHARACTER_LINK and p.deathTimer == 0 and p.forcedState == 0 and p.mount == 0 then
				v.x = (p.x + p.width*0.5) - v.width*0.5
				v.y = (p.y + p.height*0.5) - v.height*0.5
				v.heldIndex = p.idx
				p:mem(0x154, FIELD_WORD, v.idx+1)
				SFX.play(23)

				if p.isDucking == true then p.isDucking = false end
				break
			end
		end
	end
end

function billy.onDrawNPC(v)
	if v:mem(0x12A,FIELD_WORD) <= 0 then return end

	local data = v.data
	local config = NPC.config[v.id]

	if not data.initialized then return end

	Graphics.drawImageToSceneWP(
		data.wings,
		v.x,
		v.y-8,
		-- How to calculate:
		-- Just the ammo left.
		0,
		-- How to calculate:
		-- fireballSpin increases, which also slows down the fireball spinning speed.
		(32 * (math.floor(lunatime.tick() / data.wingSpeed) % 2)) + (64 * ((v.direction+1)/2)),
		64,
		32,
		data.wingPriority
	)

	if data.count > 0 and data.count < data.maxCount then
		if config.fueldisplay == true and data.bar then
			data.bar:draw{barcolor = data.barcolor, sceneCoords = true }
			data.bar.x = v.x + v.width/2
			data.bar.y = v.y - 20
			data.bar.value = data.count / data.maxCount
		end
	else
		if data.bar then
			data.bar.x = 0
			data.bar.y = 0
		end
	end
end

function billy.onInitAPI()
	NPC.registerEvent(billy, "onTickNPC")
	NPC.registerEvent(billy, "onDrawNPC")

end

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			timer = data.timer,
			projectile = data.projectile,
			additionalVelocity = data.additionalVelocity,
			inBlock = data.inBlock,
		
			angleSpeedY = data.angleSpeedY,
			fireAngle = data.fireAngle,
			count = data.count,
			maxCount = data.maxCount,
			overuseCount = data.overuseCount,
			wingSpeed = data.wingSpeed,
			wingPriority = data.wingPriority,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data._basegame
		if not data.initialized then
			return nil
		end

		data.timer = receivedData.timer
		data.projectile = receivedData.projectile
		data.additionalVelocity = receivedData.additionalVelocity
		data.inBlock = receivedData.inBlock
	
		data.angleSpeedY = receivedData.angleSpeedY
		data.fireAngle = receivedData.fireAngle
		data.count = receivedData.count
		data.maxCount = receivedData.maxCount
		data.overuseCount = receivedData.overuseCount
		data.wingSpeed = receivedData.wingSpeed
		data.wingPriority = receivedData.wingPriority
	end,
}

return billy