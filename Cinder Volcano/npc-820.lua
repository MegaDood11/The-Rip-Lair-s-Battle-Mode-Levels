local billy = {}

local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")

local utils = require("npcs/npcutils")

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,
	frames=1,
	framestyle=0,
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
	width=32,
	height=32,
	gfxwidth=32,
	gfxheight=32,

	fueldisplay = true,
	fireballrefill = 10,
	maxfireballs = 50,
	defaultprojectile = npcID+1
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
	n.data.culprit = v.data.culprit
	
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

	if data.timer == nil then
		data.timer = 0
		data.slashTimer = 0
		data.projectile = settings.projectile
		data.additionalVelocity = 0
		data.inBlock = false
		if data.projectile == 0 then
			data.projectile = NPC.config[v.id].defaultprojectile
		end

		data.angleSpeedY = 0
		data.fireAngle = 0
		data.count = NPC.config[v.id].maxfireballs
		data.maxCount = data.count
		data.fireball = Graphics.loadImageResolved("npc-" .. npcID .. "-fireball.png")
		data.fireballSpin = 2

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
	end

	data.inBlock = false

	for _,b in Block.iterateIntersecting(v.x,v.y,v.x+v.width,v.y+v.height) do
		if v.heldPlayer and Colliders.collide(v,b) and Block.SOLID_MAP[b.id] and b.isHidden == false then
			data.inBlock = true
		end
	end

	if v.heldPlayer then
		if v.heldPlayer.speedX > 0 and v.heldPlayer.direction == DIR_LEFT or v.heldPlayer.speedX < 0 and v.heldPlayer.direction == DIR_RIGHT then
			data.additionalVelocity = 0
		else
			data.additionalVelocity = math.abs(v.heldPlayer.speedX/2)
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
	
	v:mem(0x132,FIELD_WORD, v.heldIndex)
	data.culprit = v:mem(0x132,FIELD_WORD)

	if data.slashTimer > 0 then data.slashTimer = data.slashTimer - 1 end

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
			end

			-- Reimplemented the Link slash mechanics for Billy Gun
			if (Colliders.slash(p,v) or Colliders.downSlash(p,v)) and data.slashTimer == 0 then
				data.slashTimer = 4
				v.speedX = p.direction * 3
				v.speedY = -5
				v.isProjectile = true
				SFX.play(9)
			end
		end
	end

	if (data.timer >= settings.timer) and data.inBlock == false and (data.count > 0 or data.maxCount <= 0) then
		local id = data.projectile
		if id == 0 then
			id = 17
		end
				-- Determine fire angle
				if data.fireAngle < 2 or (data.fireAngle >= 4 and data.fireAngle < 6) then
					data.angleSpeedY = 0
				elseif data.fireAngle >= 2 and data.fireAngle < 4 then
					data.angleSpeedY = -1.25
				elseif data.fireAngle >= 6 and data.fireAngle < 8 then
					data.angleSpeedY = 1.5
				end

				-- Increment fire angle counter to allow patterning between:
				-- straight->up->straight->down...
				if data.fireAngle < 8 then
					data.fireAngle = data.fireAngle + 1
				else
					data.fireAngle = 0
				end
				
		local n
		if id > 0 then
			n = spawnNPC(id, v, 6 + data.additionalVelocity,data.angleSpeedY)
			data.count = data.count - 1
		else
			for i = -1,id,-1 do
				n = spawnNPC(10, v, RNG.random(2, 5))
			end
			data.count = data.count - 1
		end
		
		v.ai1 = 0
		data.timer = 0
		
		--local e = Effect.spawn(10, n.x + n.width*0.5, n.y + n.height*0.5)
		--e.x = e.x - e.width*0.5
		--e.y = e.y - e.height*0.5
		SFX.play(82)
		if data.count == 0 then
			Effect.spawn(131,v.x,v.y+4)
			SFX.play(88)
		end
	end

	-- Refill thanks to fireballs
	if data.count > data.maxCount and data.maxCount > 0 then data.count = data.maxCount end
	-- 1. Fireball contact
	for _,n in NPC.iterateIntersecting(v.x,v.y,v.x+v.width,v.y+v.height) do
		if n.id == 13 and data.count < data.maxCount and NPC.config[v.id].fireballrefill > 0 then
			SFX.play(16)
			n:kill(3)
			data.count = data.count + math.floor(NPC.config[v.id].fireballrefill)
		end

		-- Additional: if an NPC is considered ishot, try to refill the NPC with shots.
		if Colliders.collide(v,n) and ((n.id ~= 13 and n.id ~= 547 and n.id ~= NPC.config[v.id].defaultprojectile) or (n.id == 547 and Misc.canCollideWith(n,v) and Colliders.speedCollide(v,n.data._basegame.collider))) and NPC.config[n.id].ishot == true and data.count < data.maxCount and math.floor(lunatime.tick()/4 % 2) == 0 and data.maxCount > 0 then
			SFX.play(16)
			data.count = data.count + 2
			break
		end
	end
	-- 2. Held and press run by Fire Mario
	if v.heldPlayer and (v.heldPlayer.rawKeys.run == KEYS_PRESSED or v.heldPlayer.rawKeys.altRun == KEYS_PRESSED) and v.heldPlayer.powerup == 3 and data.count < data.maxCount and NPC.config[v.id].fireballrefill > 0 then
		Effect.spawn(131,v.x,v.y+4)
		SFX.play(16)
		SFX.play(18)
		data.count = data.count + math.floor(NPC.config[v.id].fireballrefill)	
	end
	-- Manage spin anims
	if data.maxCount > 0 then
		if data.count >= math.floor(data.maxCount * 0.75) then data.fireballSpin = 2 data.barcolor = Color.green
		elseif data.count < math.floor(data.maxCount * 0.75) and data.count >= math.floor(data.maxCount * 0.5) then data.fireballSpin = 4 data.barcolor = Color.yellow
		elseif data.count < math.floor(data.maxCount * 0.5) and data.count >= math.floor(data.maxCount * 0.25) then data.fireballSpin = 6 data.barcolor = Color.orange
		elseif data.count < math.floor(data.maxCount * 0.25) then data.fireballSpin = 8 data.barcolor = Color.red end
	else
		data.fireballSpin = 4
	end

	if not v.collidesBlockLeft and not v.collidesBlockRight then
   		v:mem(0x120,FIELD_BOOL,false)
	end
end

function billy.onDrawNPC(v)
	if v:mem(0x12A,FIELD_WORD) <= 0 then return end
	local data = v.data

	if (data.count > 0 and data.maxCount > 0) or data.maxCount <= 0 then
		Graphics.drawImageToSceneWP(
			data.fireball,
			v.x+8,
			v.y+10,
			-- How to calculate:
			-- Just the ammo left.
			0,
			-- How to calculate:
			-- fireballSpin increases, which also slows down the fireball spinning speed.
			16 * (math.floor(lunatime.tick() / data.fireballSpin) % 4),
			16,
			16,
			-44
		)
	end

	if data.count > 0 and data.count < data.maxCount then
		if NPC.config[v.id].fueldisplay == true and data.bar then
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

onlinePlayNPC.onlineHandlingConfig[npcID] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			projectile = data.projectile,
			timer = data.timer,
			additionalVelocity = data.additionalVelocity,
			inBlock = data.inBlock,
			angleSpeedY = data.angleSpeedY,
			fireAngle = data.fireAngle,
			count = data.count,
			maxCount = data.maxCount,
			fireball = data.fireball,
			fireballSpin = data.fireballSpin,
			bar = data.bar,
			barcolor = data.barcolor,
			culprit = data.culprit,
			slashTimer = data.slashTimer,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.projectile = receivedData.projectile
		data.timer = receivedData.timer
		data.additionalVelocity = receivedData.additionalVelocity
		data.inBlock = receivedData.inBlock
		data.angleSpeedY = receivedData.angleSpeedY
		data.fireAngle = receivedData.fireAngle
		data.count = receivedData.count
		data.maxCount = receivedData.maxCount
		data.fireball = receivedData.fireball
		data.fireballSpin = receivedData.inBlock
		data.bar = receivedData.bar
		data.barcolor = receivedData.barcolor
		data.culprit = receivedData.culprit
		data.slashTimer = receivedData.slashTimer
	end,
}

function billy.onInitAPI()
	NPC.registerEvent(billy, "onTickNPC")
	NPC.registerEvent(billy, "onDrawNPC")
end

return billy