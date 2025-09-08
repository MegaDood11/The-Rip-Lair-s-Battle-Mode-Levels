--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local onlinePlayNPC = require("scripts/onlinePlay_npc")
local npcutils = require("npcs/npcutils")

local npcIDs = {}
local friendly = {}

--Register events
function friendly.register(id)
	npcManager.registerEvent(id, friendly, "onTickEndNPC")
	npcManager.registerEvent(id, friendly, "onDrawNPC")
	npcManager.registerEvent(id, friendly, "onPostExplosionNPC")
	npcIDs[id] = true
end

local STATE_IDLE = 0
local STATE_FLY = 1
local STATE_DEAD = 2

function friendly:onPostExplosionNPC(explosion, player)
	if Colliders.collide(explosion.collider,self) then
		if self.data.state == 0 then
			self.data.state = 1
			SFX.play(NPC.config[self.id].sound)
			thing = vector.v2(
				(explosion.collider.x) - (self.x + self.width * 0.5),
				(explosion.collider.y) - (self.y + self.height * 0.5)
			):normalize() * -8
			
			self.speedX = thing.x
			self.speedY = -8
		elseif self.data.state == 2 then self.speedY = -4 end
	end
end

function friendly.onTickEndNPC(v)
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
		data.state = STATE_IDLE
		v.ai3 = 8
	end
	
	if data.state == STATE_IDLE then
		v.animationFrame = math.floor(lunatime.tick() / 8) % NPC.config[v.id].idleFrames
	elseif data.state == STATE_FLY then
		v.animationFrame = NPC.config[v.id].idleFrames
		data.timer = (data.timer or 0) + 1
		data.rotation = (data.rotation or 0) + v.speedX / 2
		if v.collidesBlockBottom then
			
			v.speedY = -v.ai3
			v.ai3 = math.clamp(v.ai3 - 2, 0, 8)
			
			if math.abs(v.speedX) > 1 then
				v.speedX = v.speedX * 0.625
				SFX.play("SFX/Land.wav")
			else
				v.speedX = 0
				if data.timer and data.timer >= 8 then
					data.rotation = 0
					if data.timer >= 32 then
						if v.ai2 == 0 then
							v.speedY = -4
							SFX.play("SFX/Skull.wav")
							data.state = 2
							v.friendly = true
						else
							data.timer = 0
							data.state = 0
							v.ai2 = 0
							v.ai3 = 8
						end
					end
				end
			end
		else
			data.timer = 0
		end
	else
		v.animationFrame = NPC.config[v.id].idleFrames + 1
	end
	
	v.despawnTimer = 180
	
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

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function friendly.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation then return end
	
	data.rotation = data.rotation or 0

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = -55,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

onlinePlayNPC.onlineHandlingConfig[npcIDs] = {
	getExtraData = function(v)
		local data = v.data
		if not data.initialized then
			return nil
		end

		return {
			state = data.state,
			rotation = data.rotation,
			MutinyLevelSplashSound = data.MutinyLevelSplashSound,
		}
	end,
	setExtraData = function(v, receivedData)
		local data = v.data
		if not data.initialized then
			return nil
		end

		data.state = receivedData.state
		data.rotation = receivedData.rotation
		data.MutinyLevelSplashSound = receivedData.MutinyLevelSplashSound
	end,
}

--Gotta return the library table!
return friendly