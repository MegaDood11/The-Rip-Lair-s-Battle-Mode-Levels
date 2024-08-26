local npcManager = require("npcManager")

local flame = {}
local npcID = NPC_ID

local flameSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsety = 2,
	frames = 4,
	framestyle = 0,
	framespeed = 4,
	luahandlesspeed = true,
	staticdirection = true,
	ignorethrownnpcs = true,
	noyoshi = true,
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = true,
	terminalvelocity = 5,
	lightradius = 100,
	lightbrightness = 1,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.orange,
	lightflicker = true,
	amplitude = 1,
	frequency = 0.5,
	vanishdelay = 100
}

npcManager.setNpcSettings(flameSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_VANISH
	},
	{
		[HARM_TYPE_LAVA]=10,
		[HARM_TYPE_VANISH]=10
	}
)

function flame.onInitAPI()
	npcManager.registerEvent(npcID, flame, "onTickNPC")
end

function flame.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.timer = 0
		data.waveTimer = 0
		data.playedSound = false
		data.initialized = true
	end
	
	v.despawnTimer = 180
    v:mem(0x124,FIELD_BOOL,true)
	
	-- if lunatime.tick() % 2 == 0 then
		-- local e = Effect.spawn(12, (v.x) + RNG.randomInt(-12, 12), (v.y - 32) + RNG.randomInt(-12, 12))
		-- e.speedY = RNG.random(-1, -6)
	-- end
	
	if v.collidesBlockBottom then
		v.speedX = 0
		v:mem(0x18, FIELD_FLOAT, 0)
		data.timer = data.timer + 1
		if data.timer >= cfg.vanishdelay then v:kill(HARM_TYPE_VANISH) end
	else
		if math.abs(v.speedX) <= cfg.amplitude then
			v.speedX = math.sin(data.waveTimer * cfg.frequency) * cfg.amplitude * v.direction
		else
			v.speedX = v.speedX * 0.975
		end
		data.timer = 0
	end
	data.waveTimer = data.waveTimer + 1
	
	if not data.playedSound and v:mem(0x138, FIELD_WORD) == 0 then
		SFX.play(16)
		data.playedSound = true
	end
end

return flame