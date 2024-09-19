local npcManager = require("npcManager")

local bobomb = {}
local npcID = NPC_ID

local stunSettings = {
	id = npcID,
	gfxoffsety=2,
	gfxheight = 32,
	gfxwidth = 24,
	nohurt=1,
	grabside=-1,
	width = 24,
	height = 32,
	frames = 2,
	framestyle = 1,
	jumphurt = 1,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=1,
	noiceball=0,
	noyoshi=0,
	fuse=4,
	nowalldeath=true
}

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	}, {
		[HARM_TYPE_NPC]=198,
		[HARM_TYPE_HELD]=198,
		[HARM_TYPE_FROMBELOW]=198,
		[HARM_TYPE_PROJECTILE_USED]=198,
		[HARM_TYPE_TAIL]=198,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

npcManager.setNpcSettings(stunSettings)

function bobomb.onInitAPI()
	npcManager.registerEvent(npcID, bobomb, "onTickNPC", "onTickStun")
	npcManager.registerEvent(npcID, bobomb, "onDrawNPC", "onDrawStun")
end

local function setDir(dir, v)
	if dir then
		v.direction = 1
	else
		v.direction = -1
	end
end

function bobomb.onDrawStun(v)
	if Defines.levelFreeze then return end
	
	v.animationTimer = 500
	local f = 0
	local cfg = NPC.config[v.id]
	if cfg.framestyle == 1 and v.direction > 0 then
		f = cfg.frames
	end
	v.animationFrame = f

	local data = v.data._basegame
	if not data.explodeTimer then
		return
	end
	
	if data.explodeTimer <= math.ceil(NPC.config[v.id].fuse 	* 65) * 0.75
	or data.explodeTimer % 2 ~= 0 then return end
	
	v.animationFrame = f + 1
end

function bobomb.onTickStun(v)
	if	Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if 	(v:mem(0x12A, FIELD_WORD) <= 0)
	or 	v.isHidden
	or  v:mem(0x138, FIELD_WORD) > 0
	or 	(v:mem(0x124, FIELD_WORD) == 0) then
		data.explodeTimer = 0
		return
	end
	
	if data.explodeTimer == nil then
		data.explodeTimer = 0
	end
	
	data.explodeTimer = data.explodeTimer + 1
	if v.speedX ~= 0 and v.collidesBlockBottom and not v:mem(0x136, FIELD_BOOL) then
		v.speedX = 0
	end
	
	--Kick Physics
	if v:mem(0x12C, FIELD_WORD) == 0 then
		for _,w in ipairs(Player.get()) do
			if v.speedX == 0 and v.collidesBlockBottom and Colliders.collide(w, v) then
				
				setDir(w.x < v.x, v)
				
				v.speedX = 3 * v.direction
				
				if v.speedY < -1 and w.upKeyPressing and not (w.leftKeyPressing or w.rightKeyPressing) then
					v.speedX = 0
				else
					SFX.play(9)
					if v.speedY == 0 then
						v.speedY = -2
					end
				end
			end
		end
	end
	
	if data.explodeTimer > math.ceil(NPC.config[v.id].fuse 	* 65) then
		v:kill(3)
		Explosion.spawn(v.x + 0.5 * v.width, v.y + 0.5 * v.height, 3)
	end
end
	
return bobomb
