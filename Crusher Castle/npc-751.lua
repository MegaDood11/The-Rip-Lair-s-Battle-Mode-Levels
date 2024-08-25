local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bobomb = {}

local npcID = NPC_ID

local bombSettings = {
	id = npcID,
	gfxoffsety=2,
	gfxheight = 32,
	gfxwidth = 24,
	width = 24,
	height = 32,
	frames = 2,
	framestyle = 1,
	jumphurt = 0,
	nogravity = 0,
	noblockcollision = 0,
	nofireball=1,
	noiceball=0,
	noyoshi=0,
	spawnid = 752, --spawnid must provide "fuse" field for both
}

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC,
		HARM_TYPE_TAIL,
		HARM_TYPE_HELD,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_SWORD,
		HARM_TYPE_LAVA
	}, {
		[HARM_TYPE_NPC]=198,
		[HARM_TYPE_TAIL]=198,
		[HARM_TYPE_HELD]=198,
		[HARM_TYPE_PROJECTILE_USED]=198,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
);

npcManager.setNpcSettings(bombSettings)

function bobomb.onInitAPI()
	npcManager.registerEvent(npcID, bobomb, "onTickNPC", "onTickBomb")
	registerEvent(bobomb, "onNPCKill", "onNPCKill", false)
end

function bobomb.onNPCKill(obj, npc, rsn)
	if npc.id ~= npcID then return end
	if rsn ~= 1 then return end
	
	obj.cancelled = true
	SFX.play(9)
	npc:transform(NPC.config[npc.id].spawnid)
	if npc.data._basegame == nil then
		npc.data._basegame = {}
	end
	npc.data._basegame.explodeTimer = 0
end

function bobomb.onTickBomb(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x124, FIELD_WORD) == 0 or v:mem(0x138, FIELD_WORD) > 0 then
		data.chaseTimer = 0
		data.explodeTimer = 0
		return
	end
	if data.chaseTimer == nil then
		data.chaseTimer = 0
		data.explodeTimer = 0
	end
	
	data.chaseTimer = data.chaseTimer + 1
	local cfg = NPC.config[v.id]

	if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) then
		data.chaseTimer = 0
	else
		v.speedX = 1.3 * v.direction
	end
end

return bobomb
