local npcManager = require("npcManager")
local rng = require("rng")

local sleepyProjectile = {}

local npcID = NPC_ID

npcManager.setNpcSettings({
	id=npcID,
	width=32,
	height=32,
	gfxheight=36,
	gfxwidth=44,
	framestyle=1,
	framespeed=8,
	frames=2,
	ignorethrownnpcs = true,
	linkshieldable = true,
	noblockcollision=true,
	speed = 2,
	nogravity=true,
	spinjumpsafe = false,
	npcblock=false,
	score = 0,
	effectID=10,
	lightradius=64,
	lightcolor=Color.orange,
	lightbrightness=1,
	jumphurt=true,
	nofireball=true,
	ishot = true,
	durability = 3,
	alwaysaim = true,
})

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	}, 
	{
		[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

function sleepyProjectile.onInitAPI()
	npcManager.registerEvent(npcID, sleepyProjectile, "onTickEndNPC")
end

--Fireballs
function sleepyProjectile.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	if v.isHidden or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x138, FIELD_WORD) > 0 then
		v.ai1 = 0
		return
	end
	
	if v.ai1 ~= 0 then return end
	
	v.ai1 = 1

	if not v.dontMove then
		local chasePlayer = player
		if player2 then
			local d1 = player.x + player.width * 0.5
			local d2 = player2.x + player2.width * 0.5
			local dr = v.x + v.width * 0.5
			if (v.direction == 1 and d1 < dr)
			or (v.direction == -1 and d1 > dr)
			or rng.randomInt(0,1) == 1 then
				chasePlayer = player2
			end
		end
		local dir = vector.v2(chasePlayer.x + 0.5 * chasePlayer.width  - (v.x + 0.5 * v.width), 
							  chasePlayer.y + 0.5 * chasePlayer.height - (v.y + 0.5 * v.height)):normalize()
							  
		dir.y = dir.y * NPC.config[v.id].speed				   
		
		if NPC.config[v.id].alwaysaim then
			v.speedX = dir.x
		else
			v.speedX = math.abs(dir.x) * v.direction
		end
		v.speedY = dir.y
	end
end

return sleepyProjectile
