
local goaltape = require("npcs/ai/goaltape")

local battlePlayer
pcall(function() battlePlayer = require("scripts/battlePlayer") end)

local onlinePlayPlayers
pcall(function() onlinePlayPlayers = require("scripts/onlinePlay_players") end)	

local hasInitialized = false

local costume = {}

costume.playersList = {}

costume.laserID = 266
costume.laserConfig = {
	width = 16,
	height = 16,
	gfxwidth = 38,
	gfxheight = 42,
	gfxoffsetx = 0,
	gfxoffsety = 8,
	frames = 4,
	framespeed = 8,
	framestyle = 0,
}

costume.goaltapeColor = Color.fromHexRGBA(0x6AA84F)

goaltape.registerVictoryPose("Kremling",1,1) -- this allows the player to use a custom frame after getting a goal tape

local hurtSFX, deathSFX, livesIMG

local characterDeathEffects = {
	[CHARACTER_MARIO] = 3,
	[CHARACTER_LUIGI] = 5,
	[CHARACTER_PEACH] = 129,
	[CHARACTER_TOAD]  = 130,
	[CHARACTER_LINK]  = 134,
}

local laserPropertiesList = table.unmap(costume.laserConfig)
local oldLaserConfig = {}

local oldGoaltapeColor = goaltape.text.characterNames[CHARACTER_LINK].color

-- gets the filename within the costume's folder directory
local function getCostumeFilename(filename)
	return "costumes/link/kremling/"..filename
end

function costume.onInit(p)
	-- If events have not been registered yet, do so
	Routine.run(function()
		-- using Routine.skip() to fix an error related to entering a level with the costume equipped beforehand not being able to find the SFX class
		while lunatime.tick() < 1 do
			Routine.skip()
		end
		if not hasInitialized then
			hurtSFX = SFX.open(getCostumeFilename("kremling-hurt.ogg"))
			deathSFX = SFX.open(getCostumeFilename("kremling-death.ogg"))
			livesIMG = Graphics.loadImage(Misc.resolveFile(getCostumeFilename("hardcoded-33-3.png")))
			if battlePlayer then
				function battlePlayer.onPlayerHarmCustom(token,p,harmType,causeInfo)
					if table.ifind(costume.playersList,p) ~= nil and onlinePlayPlayers and onlinePlayPlayers.canMakeSound(p) then
						SFX.play(hurtSFX)
					end
				end	
				function battlePlayer.onPlayerKillCustom(token,p,culprit)
					if table.ifind(costume.playersList,p) ~= nil and onlinePlayPlayers and onlinePlayPlayers.canMakeSound(p) then
						SFX.play(deathSFX)
					end
				end
			else
				registerEvent(costume,"onDraw")
			end
			hasInitialized = true
		end
		table.insert(costume.playersList,p)
		if not battlePlayer then
			goaltape.text.characterNames.useCostumeName = true
			goaltape.text.characterNames[p.character].color = costume.goaltapeColor
			
			Audio.sounds[78].sfx = hurtSFX
			Audio.sounds[80].sfx = deathSFX
			Graphics.sprites.hardcoded["33-3"].img = livesIMG
		end
	end)
	
	-- Edit link's laser a little
	if costume.laserID ~= nil and (p.character == CHARACTER_LINK) then
		local config = NPC.config[costume.laserID]

		for _,name in ipairs(laserPropertiesList) do
			oldLaserConfig[name] = config[name]
			config[name] = costume.laserConfig[name]
		end
	end
	
end

function costume.onCleanup(p)
	local spot = table.ifind(costume.playersList,p)

	if spot ~= nil then
		table.remove(costume.playersList,spot)
	end
	
	-- Clean up the laser edit
	if costume.laserID ~= nil and (p.character == CHARACTER_LINK) then
		local config = NPC.config[costume.laserID]

		for _,name in ipairs(laserPropertiesList) do
			config[name] = oldLaserConfig[name] or config[name]
			oldLaserConfig[name] = nil
		end
	end
	
	if not battlePlayer then
		goaltape.text.characterNames.useCostumeName = false
		goaltape.text.characterNames[p.character].color = oldGoaltapeColor
		Audio.sounds[78].sfx = nil
		Audio.sounds[80].sfx = nil
		Graphics.sprites.hardcoded["33-3"].img = nil
	end
end

function costume.onDraw()
	-- Change death effects
	if costume.playersList[1] ~= nil then
		local deathEffectID = characterDeathEffects[costume.playersList[1].character]

		for _,e in ipairs(Effect.get(deathEffectID)) do
			e.animationFrame = -999

			local image = Graphics.sprites.effect[e.id].img

			local width = image.width
			local height = image.height/2

			local frame = math.max(math.sign(e.speedX), 0)

			Graphics.drawImageToSceneWP(image, e.x + e.width*0.5 - width*0.5,e.y + e.height*0.5 - height*0.5, 0,frame*height, width,height, -5)
		end
	end
end


return costume
