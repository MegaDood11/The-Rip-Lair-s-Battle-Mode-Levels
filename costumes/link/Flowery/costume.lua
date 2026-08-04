
local goaltape = require("npcs/ai/goaltape")

local battlePlayer
pcall(function() battlePlayer = require("scripts/battlePlayer") end)

local battleGeneral
pcall(function() battleGeneral = require("scripts/battleGeneral") end)

local onlinePlay
pcall(function() onlinePlay = require("scripts/onlinePlay") end)	

local onlinePlayPlayers
pcall(function() onlinePlayPlayers = require("scripts/onlinePlay_players") end)	

local battleMessages
pcall(function() battleMessages = require("scripts/battleMessages") end)	

local textFiles
pcall(function() textFiles = require("scripts/textFiles") end)	

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

goaltape.registerVictoryPose("Flowery",28,28) -- this allows the player to use a custom frame after getting a goal tape

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
	return "costumes/link/Flowery/"..filename
end

local function yeahIThinkWeJustWon(index)
    if onlinePlay.currentMode == onlinePlay.MODE_OFFLINE then
        return false
    end

    if battlePlayer.teamsAreEnabled() then
        return (index == battlePlayer.getTeam(onlinePlay.playerIdx))
    else
        return (index == onlinePlay.playerIdx)
    end
end

local function startVictoryInternal(index)
    local screenWidth,screenHeight = battleGeneral.getScreenSize()

    if index > 0 then
        local color,name

        if battlePlayer.teamsAreEnabled() then
            color = battleGeneral.teamColors[index]:lerp(Color.white,0.5)
            name = textFiles.battleMessages.victoryTeamNames[index]
        else
            color = battlePlayer.getColor(index):lerp(Color.white,0.5)
            name = battlePlayer.getName(index)
			
			for _,p in ipairs(Player.get()) do			
				if table.ifind(costume.playersList,p) ~= nil and onlinePlayPlayers and onlinePlayPlayers.canMakeSound(p) and p.idx == index then
					SFX.play(RNG.irandomEntry{victory1, victory2})
				end
			end
        end

        battleMessages.spawnText{
            message = textFiles.funcs.replace(textFiles.battleMessages.victoryTop,{NAME = name}),
            color = color,delay = 0,

            x = screenWidth*0.5,y = screenHeight*0.5,
            horizontalDirection = -1,pivot = vector(0.5,1),
        }
        battleMessages.spawnText{
            message = textFiles.funcs.replace(textFiles.battleMessages.victoryBottom,{NAME = name}),
            color = color,delay = 32,

            x = screenWidth*0.5,y = screenHeight*0.5,
            horizontalDirection = 1,pivot = vector(0.5,0),
        }

        SFX.play(52)
    else
        battleMessages.spawnText{
            message = textFiles.battleMessages.victoryDraw,
            color = Color.lightgrey,delay = 0,

            x = screenWidth*0.5,y = screenHeight*0.5,
            horizontalDirection = -1,pivot = vector(0.5,0.5),
        }

        SFX.play(Misc.resolveSoundFile("resources/battleDraw"))
    end

    if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE and battleGeneral.mode >= 0 then
        if yeahIThinkWeJustWon(index) then
            battleGeneral.saveData.onlineVictoriesByMode[battleGeneral.mode] = (battleGeneral.saveData.onlineVictoriesByMode[battleGeneral.mode] or 0) + 1
        end

        battleGeneral.saveData.onlineGamesByMode[battleGeneral.mode] = (battleGeneral.saveData.onlineGamesByMode[battleGeneral.mode] or 0) + 1
    end

    battleMessages.victoryActive = true
    battleMessages.victoryTimer = 0
    
    battleMessages.victoriousPlayerIdx = index

    battleGeneral.gameData.lastVictoriousPlayers = {}

    if battlePlayer.teamsAreEnabled() then
        for _,user in ipairs(onlinePlay.getUsers()) do
            if battlePlayer.getTeam(user.playerIdx) == index then
                table.insert(battleGeneral.gameData.lastVictoriousPlayers,user.playerIdx)
            end
        end
    elseif index > 0 then
        table.insert(battleGeneral.gameData.lastVictoriousPlayers,index)
    end


    Audio.SeizeStream(-1)
    Audio.MusicStop()
end

function costume.onInit(p)
	-- If events have not been registered yet, do so
	Routine.run(function()
		-- using Routine.skip() to fix an error related to entering a level with the costume equipped beforehand not being able to find the SFX class
		while lunatime.tick() < 1 do
			Routine.skip()
		end
		
		table.insert(costume.playersList,p)
		
		if not hasInitialized then
			hurtSFX = SFX.open(getCostumeFilename("flowery-hit.ogg"))
			deathSFX = SFX.open(getCostumeFilename("flowery-death.ogg"))
			blockSFX = SFX.open(getCostumeFilename("flowery-shield.ogg"))
			powerupSFX = SFX.open(getCostumeFilename("flowery-powerup.ogg"))
			heartSFX = SFX.open(getCostumeFilename("flowery-heart.ogg"))
			attackSFX = SFX.open(getCostumeFilename("flowery-attack.ogg"))
			victory1 = SFX.open(getCostumeFilename("flowery-according-to-plant.ogg"))
			victory2 = SFX.open(getCostumeFilename("flowery-sorry-guys.wav"))
			fallingSFX = SFX.open(getCostumeFilename("flowery-falling.wav"))
			introSFX = SFX.open(getCostumeFilename("flowery-leaf-it-to-me.wav"))
			livesIMG = Graphics.loadImage(Misc.resolveFile(getCostumeFilename("hardcoded-33-3.png")))
			
			
			if battlePlayer then
				function battlePlayer.onPlayerHarmCustom(token,p,harmType,causeInfo)
					if table.ifind(costume.playersList,p) ~= nil and onlinePlayPlayers and onlinePlayPlayers.canMakeSound(p) then
						SFX.play(hurtSFX)
					end
				end	
				
				function battlePlayer.onPlayerKillCustom(token,p,culprit)
					if table.ifind(costume.playersList,p) ~= nil and onlinePlayPlayers and onlinePlayPlayers.canMakeSound(p) then
						if p.y >= camera.y + camera.height then
							SFX.play(fallingSFX)
						else
							SFX.play(deathSFX)
						end
					end
				end
				
				function battlePlayer.onPlayerHarmCustom(token,hitPlayer,harmType,causeInfo)
					if not causeInfo.playerIdx or causeInfo.playerIdx == hitPlayer.idx then return end
					if battlePlayer.playersAreOnSameTeam(hitPlayer.idx,causeInfo.playerIdx) then return end
					
					if causeInfo.cause == battlePlayer.HARM_CAUSE.PLAYER_SWORD and (table.ifind(costume.playersList,p) ~= nil and causeInfo.playerIdx == p.idx) then
						SFX.play(attackSFX)
					end
				end
				
				registerEvent(costume,"onPostNPCHarm")
				
				if table.ifind(costume.playersList,p) ~= nil and onlinePlayPlayers and onlinePlayPlayers.canMakeSound(p) and Level.filename() ~= "Hub.lvlx" and lunatime.tick() == 1 then
					SFX.play(introSFX)
				end
				
				function battleMessages.startVictory(index)
					if battleMessages.victoryActive then
						return
					end
				
					if onlinePlay.currentMode == onlinePlay.MODE_HOST then
						for _,p in ipairs(Player.get()) do			
							if table.ifind(costume.playersList,p) ~= nil and p.idx == index then
								SFX.play(RNG.irandomEntry{victory1, victory2})
							end
						end
					elseif onlinePlay.currentMode == onlinePlay.MODE_CLIENT then
						error("Cannot start a victory as a client",2)
					end

					startVictoryInternal(index)
				end	
			else
				registerEvent(costume,"onTick")
				registerEvent(costume,"onDraw")
			end
			hasInitialized = true
		end
		
		if not battlePlayer then
			goaltape.text.characterNames.useCostumeName = true
			goaltape.text.characterNames[p.character].color = costume.goaltapeColor
			
			Audio.sounds[78].sfx = hurtSFX
			Audio.sounds[79].sfx = heartSFX
			Audio.sounds[83].sfx = powerupSFX
			Audio.sounds[85].sfx = blockSFX
			Audio.sounds[77].sfx = attackSFX
			
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

function costume.onPostNPCHarm(v, reason, culprit)
	for _,p in ipairs(battlePlayer.getActivePlayers()) do
		if (Colliders.slash(p, v) or Colliders.downSlash(p, v)) and table.ifind(costume.playersList,p) ~= nil and onlinePlayPlayers and onlinePlayPlayers.canMakeSound(p) then
			SFX.play(attackSFX)
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

function costume.onTick()
	if battlePlayer then return end
	for _,p in ipairs(Player.get()) do
		if p.character ~= CHARACTER_LINK and not p:getCostume("Flowery") then return end
		if lunatime.tick() == 2 then SFX.play(introSFX) end
		if p.y >= camera.y + camera.height then
			Audio.sounds[80].sfx = fallingSFX
		else
			Audio.sounds[80].sfx = deathSFX
		end
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
