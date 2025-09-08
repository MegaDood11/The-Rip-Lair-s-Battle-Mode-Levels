local battleGeneral = require("scripts/battleGeneral")
local battleTimer = require("scripts/battleTimer")
local onlinePlay = require("scripts/onlinePlay")
local onlinePlayPlayers = require("scripts/onlinePlay_players")
local battlePlayer = require("scripts/battlePlayer")
local booMushroom = require("scripts/booMushroom")


local floorHeight = -200032
local tunnelSpeed = 12
local warningSignGradient = 200

local minStarCatcherTunnelDelay = 40	-- min seconds between each tunnel segment
local extraStarCatcherTunnelDelay = 40	-- up to this many seconds extra on min delay

local minStoneCarrierTunnelDelay = 50	-- min seconds between each tunnel segment
local extraStoneCarrierTunnelDelay = 50	-- up to this many seconds extra on min delay

local minClassicModeTunnelDelay = 30	-- min seconds between each tunnel segment
local extraClassicModeTunnelDelay = 50	-- up to this many seconds extra on min delay

local lastStarCatcherTunnelTime = 40	-- how much time has to be left for a tunnel to be able to appear in star catcher
local lastStoneCarrierTunnelTime = 60	-- how much time has to be left for a tunnel to be able to appear in stone carrier
local lastClassicModeTunnelTime = 20	-- how much time has to be left for a tunnel to be able to appear in classic mode

local showWarningArea = false

local warningArea = {
	texture = Graphics.loadImageResolved("warning_gradient.png"),
	signTexture = Graphics.loadImageResolved("warning_indicator.png"),
	signFrame = 0,
	signAnimationSpeed = 4,
	signScale = 2,
	signScaleSpeed = 0.005,
	x = 0,
	y = 0,
	width = 400,
	height = 176,
	fillX = 0
}


local TrainLevelEventHandlingCommand = onlinePlay.createCommand("eventHandling",onlinePlay.IMPORTANCE_MAJOR)	-- currently not used, might be if event handling is too weird
local trainLevelHitGroundCommand = onlinePlay.createCommand("hitGround",onlinePlay.IMPORTANCE_MAJOR)			-- event for if someone touches harmful, evil, outrageously mean rails that do damgae


local function canGetHarmedByRail(p)
	local bdata = battlePlayer.getPlayerData(p)

	return (
		bdata.respawnTimer == 0 and
		p:mem(0x140,FIELD_WORD) == 0 and
		p.forcedState == FORCEDSTATE_NONE and
		p.tanookiStatueTimer == 0
	)

end

local function isOnGroundRedigit(p) -- grounded player check. surprisingly, doing it the redigit way is more reliable than player:is On Ground()
    return (
        p.speedY == 0
        or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC (this is -1 when standing on a moving block. thanks redigit.)
        or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
    )
end

local function canGetWarningSign(p)
	local bdata = battlePlayer.getPlayerData(p)
	--Misc.dialog(p.isValid, p.deathTimer)
	return (
		p.isValid and
		bdata.respawnTimer == 0 and
		not bdata.forfeited and
		bdata.isActive and
		not booMushroom.isActive(p) and
		p.x >= warningArea.x and
		onlinePlayPlayers.ownsPlayer(p)
	)
end

local function resetWarningAreaPos()
	warningArea.x = player.sectionObj.boundary.right
	warningArea.y = player.sectionObj.boundary.top
	warningArea.fillX = warningArea.x
	showWarningArea = false
end

local function eventHandling(name)	-- synced for online play
	if name == "shyGuy" then
		Audio.MusicInstChannelUnmute(2)	-- play shy guy chanting
	elseif name == "noShyGuy" then
		Audio.MusicInstChannelMute(2)	-- don't play shy guy chanting
	elseif name == "tunnel" then
		Audio.MusicInstChannelMute(0)
		Audio.MusicInstChannelUnmute(1)
	elseif name == "noTunnel" then
		Audio.MusicInstChannelMute(1)
		Audio.MusicInstChannelUnmute(0)
	elseif name == "warning" then
		Routine.run(function()
			showWarningArea = true
			SFX.play("train_whistle.mp3")	-- play the train whistle sound for everyone regardless of their position
			local signWaitTimer = 0
			while (warningArea.x + warningArea.width >= player.sectionObj.boundary.left) do
				warningArea.x = warningArea.x - tunnelSpeed
				Routine.waitFrames(1)
				if signWaitTimer == 0 then
					warningArea.signFrame = (warningArea.signFrame + 1) % 2
				end
				signWaitTimer = (signWaitTimer + 1) % warningArea.signAnimationSpeed
				warningArea.signScale = warningArea.signScale + warningArea.signScaleSpeed
			end
			triggerEvent("showAndMoveTunnel")
			warningArea.signScale = 4
			r = Routine.run( function()
				while true do
					warningArea.x = warningArea.x - tunnelSpeed
					if signWaitTimer == 0 then
					warningArea.signFrame = (warningArea.signFrame + 1) % 2
					end
					signWaitTimer = (signWaitTimer + 1) % warningArea.signAnimationSpeed
					Routine.waitFrames(1)
				end
				
			end)
			Routine.wait(6)
			r:abort()
			
			resetWarningAreaPos()
		end)
	end
end

local function hitGround(p)		-- logic for when a player hits the rails and taking damage. Synced via commands
	local bdata = battlePlayer.getPlayerData(p)
	
	-- for all players that touch the rails at the bottom
	if p.y + p.height >= floorHeight then
		-- if they aren't dying, launch them up and back
		if bdata.respawnTimer == 0 then
			p.speedY = -14
			p.speedX = -p.speedX
			if math.abs(p.speedX) > 1 then
				p.slidingOnSlope = true
			end
		end
		
		-- if they can get harmed by the rail now, set I-frames and harm the player
		if canGetHarmedByRail(p) then
			if onlinePlayPlayers.canMakeSound(p) then	-- only play sound when on screen
				SFX.play(39)	-- birdo hit sfx
			end
			p:harm()
			-- p.data.isHarmedByLandingOnRail
			p:mem(0x140,FIELD_WORD,150)
		end
	end
end

local function handleTunnel()
	-- set the tunnel times specific to mode
	local minTunnelDelay, extraTunnelDelay, lastTunnelTime = minStarCatcherTunnelDelay, extraStarCatcherTunnelDelay, lastStarCatcherTunnelTime	-- use star catcher values by default
	if battleGeneral.mode == battleGeneral.gameMode.CLASSIC then
		minTunnelDelay, extraTunnelDelay, lastTunnelTime = minClassicModeTunnelDelay, extraClassicModeTunnelDelay, lastClassicModeTunnelTime
	elseif battleGeneral.mode == battleGeneral.gameMode.STONE then
		minTunnelDelay, extraTunnelDelay, lastTunnelTime = minStoneCarrierTunnelDelay, extraStoneCarrierTunnelDelay, lastStoneCarrierTunnelTime
	end
	
	Routine.wait(math.random(minTunnelDelay,minTunnelDelay + extraTunnelDelay))	-- wait for a random time until the first tunnel appears
	
	while (not battleTimer.isActive or battleTimer.secondsLeft >= lastTunnelTime) do
		triggerEvent("warning")
		
		
		Routine.wait(math.random(minTunnelDelay,minTunnelDelay + extraTunnelDelay))	-- wait for a random time until the next tunnel appears
	end
end

function onEvent(name)
	--if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then			-- in case commands work better
	--	TrainLevelEventHandlingCommand:send(0,p.idx)
	--end
	
	--if onlinePlayPlayers.ownsPlayer(p) then
	--
	--end
	
	eventHandling(name)	-- might work well enough if everyone handles it on their own
	
end

function onStart()
	
	if onlinePlay.currentMode ~= onlinePlay.MODE_CLIENT then	-- host only will do tunnel handling
		Routine.run(handleTunnel)
	end


	resetWarningAreaPos()
end

function onTick()
	
	for _,p in ipairs(Player.get()) do
		if onlinePlay.currentMode ~= onlinePlay.MODE_OFFLINE then
			trainLevelHitGroundCommand:send(0,p.idx)
		end
	
		if onlinePlayPlayers.ownsPlayer(p) then
			hitGround(p)
		end
	end
end

function onDraw()
	
	if showWarningArea then
		
		Graphics.drawBox{
			texture = warningArea.texture,
			x = warningArea.x,
			y = warningArea.y,
			centered = false,
			width = warningArea.width,
			height = warningArea.height,
			sceneCoords = true,
			sourceX = 0,
			sourceY = 0,
			sourceWidth = warningArea.width,
			sourceHeight = warningArea.height,
			priority = -96,
			rotation = 0,
			color = Color.white .. 1
		}
		Graphics.drawBox{
			texture = warningArea.texture,
			x = warningArea.x + warningArea.width,
			y = warningArea.y,
			centered = false,
			width = warningArea.fillX - (warningArea.x + warningArea.width),
			height = warningArea.height,
			sceneCoords = true,
			sourceX = 399,
			sourceY = 0,
			sourceWidth = 1,
			sourceHeight = warningArea.height,
			priority = -96,
			rotation = 0,
			color = Color.white .. 1
		}
		
		for _,p in ipairs(Player.get()) do
			if canGetWarningSign(p) then
				local transparency = math.clamp((p.x-warningArea.x) / warningSignGradient, 0, 1)
				local distance = math.clamp(((p.x-warningArea.x) / ((p.sectionObj.boundary.right - p.sectionObj.boundary.left)*0.5))+2,2, 4)
				Graphics.drawBox{
					texture = warningArea.signTexture,
					x = p.x + p.width * 0.5,
					y = math.min(p.y - 32, warningArea.y + warningArea.height * 0.5),
					centered = true,
					width = 16 * (distance),
					height = 16 * (distance),
					sceneCoords = true,
					sourceX = 0,
					sourceY = 16 * warningArea.signFrame,
					sourceWidth = 16,
					sourceHeight = 16,
					priority = -95,
					rotation = 0,
					color = Color.white .. transparency
				}
			end
		
		end
	
	end
end