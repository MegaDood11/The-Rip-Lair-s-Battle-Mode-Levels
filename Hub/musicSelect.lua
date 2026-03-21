local battleMenu = require("scripts/battleMenu")
local textFiles = require("scripts/textFiles")

local battleGeneral = require("scripts/battleGeneral")

local playerSelect = require("playerSelect")

local musicSelect = {}


musicSelect.section = 0

musicSelect.songPaths = {
    numberlessMoments = "resources/hubMusic/Numberless Moments - by Jazzman287.spc|0;g=2.4;",
    abstractMap = "resources/hubMusic/Abstract Map - VLDC9.spc|0;g=1.7;",
    alternaSite6 = "resources/hubMusic/Alterna Site 6 (Full Version) - Splatoon 3.ogg",
    regret = "resources/hubMusic/#8 Regret - Splatoon 2 Octo Expansion.ogg",
    waitingRoom = "resources/hubMusic/Waiting To Join - Mario Kart Wii.ogg",
	WFC = "resources/hubMusic/Nintendo WFC Menu - Mario Kart DS.ogg",
    dreamyWakeport = "resources/hubMusic/Dreamy Wakeport Repose.ogg",
    flipsideArcade = "resources/hubMusic/Flipside Arcade - Super Paper Mario.ogg",
    readyToFight = "resources/hubMusic/Get Ready to Fight! - Multiversus.ogg",
	greenRoom = "resources/hubMusic/Welcome to the Green Room - Deltarune.ogg",
	stickerbrush = "resources/hubMusic/Stickerbush Symphony - Donkey Kong Country 2.spc|0;g=2.4;",
    velkommen = "resources/hubMusic/Velkommen - Windows XP.ogg",
	reconstruction = "resources/hubMusic/Reconstruction - Poly Bridge 2.ogg",
	drawful = "resources/hubMusic/Background Loop (Drawful) - Jackbox.ogg",
	wordspud = "resources/hubMusic/Lobby (WordSpud) - Jackbox.ogg",
	pollMine = "resources/hubMusic/The Poll Mine - Jackbox.ogg",
	rosalina = "resources/hubMusic/Rosalina in the Observatory - Super Mario Galaxy.ogg",
	LA = "resources/hubMusic/Los Angeles Laps - Mario Kart World.ogg",
	yoshiStar = "resources/hubMusic/Yoshi Star Galaxy - Mario Kart World.ogg",
	breakSilence = "resources/hubMusic/Break Silence - Ristar.vgm|0;g=2.4;",
	allStarRestArea = "resources/hubMusic/All-Star Rest Area - Qumu.ogg",
	trophy = "resources/hubMusic/Trophy - Super Smash Bros. Melee.ogg",
	menuSSF = "resources/hubMusic/Menu - Super Smash Flash.ogg",
	floodLobby = "resources/hubMusic/Lobby - Flood Escape 2.ogg",
	resonance = "resources/hubMusic/Resonance - HOME.ogg",
	sonicExtras = "resources/hubMusic/Extras Menu - Sonic Mega Collection.ogg",
	airRidersMenu = "resources/hubMusic/Menu - Kirby Air Riders.ogg",
	pokemonGoodbye = "resources/hubMusic/I Don't Wanna Say Goodbye - PKM.ogg",
}

musicSelect.songList = {
    "numberlessMoments","abstractMap","alternaSite6","regret","waitingRoom","WFC","dreamyWakeport","flipsideArcade","readyToFight","greenRoom","stickerbrush","velkommen",
	"reconstruction","drawful","wordspud","pollMine","rosalina","LA","yoshiStar","breakSilence","allStarRestArea","trophy","menuSSF","floodLobby","resonance","sonicExtras",
	"airRidersMenu","pokemonGoodbye"
}

battleGeneral.saveData.hubMusic = battleGeneral.saveData.hubMusic or "random"


local changeSound = Misc.resolveSoundFile("resources/songChange")

local changeSongRoutine

local function setSong()
    local name = battleGeneral.saveData.hubMusic

    if name == "random" then -- if random, pick one
        if playerSelect.titleMenu.isOpen and battleGeneral.saveData.playSessions == 1 then -- for your first ever start up...
            name = "alternaSite6"
        else
            name = RNG.irandomEntry(musicSelect.songList)
        end
    elseif name == "none" then
        Section(musicSelect.section).music = 0
        return
    end

    Section(musicSelect.section).music = musicSelect.songPaths[name]
end

local function changeSong(newName)
    SFX.play(14)
    
    if battleGeneral.saveData.hubMusic == newName then
        return
    end

    if changeSongRoutine ~= nil and changeSongRoutine.isValid then
        -- If already doing this, stop it
        changeSongRoutine:abort()
    end
    
    -- Set it
    battleGeneral.saveData.hubMusic = newName

    -- Fade out previous song
    while (Audio.MusicVolume() > 0) do
        Audio.MusicVolume(math.max(0,Audio.MusicVolume() - 2))
        Routine.waitFrames(1,true)
    end

    Section(musicSelect.section).music = 0
    Audio.MusicVolume(51)

    if newName ~= "none" and not battleGeneral.musicMuted() then
        -- Let the sound effect play
        SFX.play(changeSound)

        Routine.wait(1.5,true)
    end

    -- Change path
    setSong()
end


-- Menu
local function addSongOption(menu,name)
    local text = textFiles.hubMusic[name]

    local fullText = text.name
    if text.source ~= nil then
        fullText = fullText.. "\n<color lightgrey>".. text.source.. "</color>"
    end

    menu:addOption{text = fullText,runFunction = function(option)
        changeSongRoutine = Routine.run(changeSong,name)
        battleMenu.closeAll()
    end}
end

local optionFormatSettings = table.join({textScale = 1.7,boxMarginX = 24,boxMarginY = 12, hasBox = false, getGraphicsPosFunc = function(option)
	local menu = option.menu

	local selectedOptionNow = menu.options[menu.optionIdx]
	local selectedOptionOld = menu.options[menu.optionIdxFadeStart]
	local y = math.lerp(selectedOptionNow.y,selectedOptionOld.y,menu.optionIdxFade)
	menu.elementsHeight = 512
	menu.elementsWidth = 720
	
	menu.options[1].y = -160
	
	if (option.y) - y * 0.5 <= -140 or (option.y) - y * 0.5 >= 252 then
		option.x = 10000
	else
		for i = 1, #menu.options do
			menu.options[i].x = 200 + (-400 * (i % 2))
			if i % 2 == 1 then menu.options[i].offsetUp = 20 end
			menu.options[i].y = -200 + (20 * i) + (menu.options[i].offsetUp or 0)
		end
	end
	
	for _,p in ipairs(Player.get()) do
		if menu.options[menu.optionIdx] ~= menu.options[1] and menu.options[menu.optionIdx] ~= menu.options[2] and menu.options[menu.optionIdx] ~= menu.options[#menu.options] and menu.options[menu.optionIdx] ~= menu.options[#menu.options - 1] then
			p.data.keyDelay = 2
		end
		
		if (player.rawKeys.up == KEYS_PRESSED and y <= -160 and (menu.options[menu.optionIdx] == menu.options[1] or menu.options[menu.optionIdx] == menu.options[2])) or (player.rawKeys.down == KEYS_PRESSED and y >= 400 and (menu.options[menu.optionIdx] == menu.options[#menu.options] or menu.options[menu.optionIdx] == menu.options[#menu.options - 1])) then
			if p.data.keyDelay <= 0 then
				if y <= -160 then
					if menu.options[menu.optionIdx] == menu.options[1] then
						menu:changeOptionIdx(#menu.options - 1)
					else
						menu:changeOptionIdx(#menu.options)
					end
				else
					if menu.options[menu.optionIdx] == menu.options[#menu.options] then
						menu:changeOptionIdx(2)
					else
						menu:changeOptionIdx(1)
					end
				end
			end
		end
	end
	
	return option.x, math.clamp((option.y) - y*0.5, -140, 252)
end},optionFormat)

local textFormatSettings = table.join({hasBox = true,textScale = 2,textMaxWidth = 384,textColor = Color.lightgrey,selectionGap = 21, getGraphicsPosFunc = function(option)
	option.y = -212
	option.x = 0
	return option.x, option.y
end},textFormat)

musicSelect.menu = battleMenu.createMenu{
    format = {
        hasBackground = true,hasBox = true,elementGapY = 12, cameraScale = 1,
        offsetX = 384,offsetY = 96,rotation = 10,scale = 0.75, hasPinchers = true, maxElementsPerLine = 2,
    },
    optionFormat = optionFormatSettings,
    textFormat = textFormatSettings,
}
musicSelect.menu.openFunc = function(menu)
    -- Select a song! text
    menu:addText{text = textFiles.hubMusic.header}

    -- Other options
    addSongOption(menu,"random")
    addSongOption(menu,"none")

    -- Actual songs
    for _,name in ipairs(musicSelect.songList) do
        addSongOption(menu,name)
    end
end


function musicSelect.onStart()
    setSong()
end

function musicSelect.onInputUpdate()

	for _,p in ipairs(Player.get()) do
		p.data.keyDelay = (p.data.keyDelay or 0) - 1
		if (p.rawKeys.up == KEYS_PRESSED or p.rawKeys.down == KEYS_PRESSED) and p.data.keyDelay <= 0 then p.data.keyDelay = 2 end
	end
end

function musicSelect.onInitAPI()
    registerEvent(musicSelect,"onStart")
	registerEvent(musicSelect,"onInputUpdate")
end


return musicSelect