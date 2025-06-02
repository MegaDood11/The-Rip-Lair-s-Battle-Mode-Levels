--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local verlet = require("verletrope2")
local banner = require("banner")

--Create the library table
local lib = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local libSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	notcointransformable = true,
	nohurt=true,
	nogravity = true, --FALSE
	noblockcollision = true, --TRUE
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(libSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{}, 
	{}
);

--Register events
function lib.onInitAPI()
	npcManager.registerEvent(npcID, lib, "onTickNPC")
	npcManager.registerEvent(npcID, lib, "onDrawNPC")
	
	registerEvent(lib, "onTick")
end

local windOffset = vector(0,0)

function lib.onTick()
	windOffset.x = windOffset.x + 1
	windOffset.y = windOffset.y + 1
end

function lib.onDrawNPC(v)
	local bannerData = v.data.bannerData
	
	if(bannerData) then
		bannerData:draw(v)
	end
end

local function windForce(pos, vel, windMod)
	local globalWind = RNG.Perlin:get(windOffset.x * 0.7)
	globalWind = globalWind * globalWind * 10
	local perlinX = RNG.Perlin:get2d((pos.x + windOffset.x) * 2, (pos.y + windOffset.y) * 2) - 0.5
	--Misc.dialog(perlinX)
	return vector((perlinX * 2 + 0.2) * globalWind * windMod, 0)
end 

function lib.onTickNPC(v)
	local data = v.data
	local settings = v.data._settings
	
	local bannerData = data.bannerData
	
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = 0
		
		if(settings.attachNPC or false) then 
			for _, other in NPC.iterateIntersecting(v.x,v.y,v.x + v.width,v.y + v.height) do
				if(other.id ~= v.id) then
					data.attachedNPC = other
					break
				end
			end
		end
		
		local windMod = settings.windMod or 1
		local windForceWithMod = function(pos, vel) return windForce(pos, vel, windMod) end
		
		
		bannerData = banner.setup(v, settings.preset or 1, settings.offsetY or 0)
		--data.cloth = verlet.Cloth(vector(v.x, v.y), vector(v.x + clothwidth, v.y), vector(v.x, v.y + clothlength), vector(v.x + clothwidth, v.y + clothlength), 7, 10, Defines.npc_grav * 2, true)
		--data.cloth:addForceFunc(function(pos, vel) return vector(0.3 * (math.sin((pos.x + data.timer * 4) * 0.05) + 1) * 0.5, 0) end)
		bannerData.cloth:addForceFunc(windForceWithMod)
	end
	
	data.timer = data.timer + 1
	
	if(data.attachedNPC and data.attachedNPC.isValid) then
		local other = data.attachedNPC
		
		v.x, v.y = other.x + other.width / 2 - v.width / 2, other.y
	end

	bannerData.originX = v.x + v.width / 2
	bannerData.originY = v.y + v.height / 2
	
	bannerData:update()
end

--Gotta return the library table!
return lib