local lightning = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

npcManager.setNpcSettings({
	id = npcID,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	gfxwidth = 32, 
	gfxheight = 32, 
	width = 16,
	height = 32,
	frames = 1,
	harmlessgrab=true,
	harmlessthrown=false,
	ignorethrownnpcs = true,
	framespeed = 8,
	framestyle = 0,
	nofireball=1,
	noiceball=-1,
	noyoshi=1,
	nohurt=-1,
	speed=1,
	nogravity=0,
	noblockcollision=-1,
	jumphurt = 1,
	nowaterphysics=true,
	spinjumpsafe = false,
	lightradius=32,
	lightbrightness=1,
	lightcolor=Color.white,
	iselectric = true,

	spawnid = 362
})

function lightning.onInitAPI()
	npcManager.registerEvent(npcID, lightning, "onTickNPC")
end

local function initFire(v, f, dir)
	f.data._basegame = {}
	f.data._basegame.dir = dir
	f.data._basegame.spread = v.data._basegame.spread - 1
	f.data._basegame.wasThrown = v.data._basegame.wasThrown or false
	if v.data._basegame.friendly ~= nil then
		f.friendly = v.data._basegame.friendly
	else
		f.friendly = v.friendly
	end
	f.layerName = "Spawned NPCs"
	return f
end

function lightning.onTickNPC(v)
	if Defines.levelFreeze
		or v.isHidden
		or v:mem(0x12C, FIELD_WORD) > 0
		or v:mem(0x138, FIELD_WORD) > 0
		or v:mem(0x12A, FIELD_WORD) <= 0 then return end

	local data = v.data._basegame
	
	if data.feet == nil then
		data.feet = Colliders.Box(0,0,v.width,1)
		data.lastFrameCollision = true
	end

	if v.speedY > 0 then
		data.feet.x = v.x
		data.feet.y = v.y + v.height
		local collidesWithSolid = false
		local footCollisions = Colliders.getColliding{
		
			a=	data.feet,
			b=	Block.SOLID ..
				Block.PLAYER ..
				Block.SEMISOLID,
			btype = Colliders.BLOCK,
			collisionGroup = v.collisionGroup,
			filter= function(other)
				if (not collidesWithSolid and not other.isHidden and other:mem(0x5A, FIELD_WORD) == 0) then
					if Block.SOLID_MAP[other.id] or Block.PLAYER_MAP[other.id] then
						return true
					end
					if data.feet.y <= other.y + 8 then
						return true
					end
				end
				return false
			end
			
		}
		
		if #footCollisions > 0 then
			collidesWithSolid = true
			data.culprit = footCollisions[1]
			if not data.lastFrameCollision then
				local id = NPC.config[v.id].spawnid
				local f = NPC.spawn(id, v.x + 0.5 * v.width, data.culprit.y - 0.5 * NPC.config[id].height, v:mem(0x146, FIELD_WORD), false, true)
				if NPC.config[id].spread then
					data.spread = NPC.config[id].spread + 1
					initFire(v, f, 0)
				end
				SFX.play(42)
				v:kill(9)
				return
			end
		end
		data.lastFrameCollision = collidesWithSolid
	end
end

return lightning