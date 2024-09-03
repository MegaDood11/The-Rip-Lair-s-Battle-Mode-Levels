--[[
	icantswim.lua v1.0.1
	
	A library that puts players in a low gravity state when they're in water, instead of a swimming state.
	
	by cold soup
]]

local icantswim = {}

-------- modifiable variables --------

-- filenames and effect IDs
icantswim.splashEffectID = 950
icantswim.bubbleEffectID = 951
icantswim.splashSound = Audio.SfxOpen("splash.ogg")

-- booleans to disable or enable effects/sounds
icantswim.doSplash = true
icantswim.doBubble = true
icantswim.doSplashSound = true

icantswim.waterRunSpeed = 4 -- run speed of the player in water (base fall speed is 12)

---------- code starts here ----------

local waterBoxes = {}
local currentBox

local jumpheights = {40,45,40,35,40}

local bettereffects = require("base/game/bettereffects")

function icantswim.onInitAPI()
	registerEvent(icantswim, "onStart")
	registerEvent(icantswim, "onTick")
	registerEvent(icantswim, "onExit")
	registerEvent(icantswim, "onNPCHarm")
end

function icantswim.onNPCHarm(eventObj, v, reason, culprit)
	if (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) and (type(culprit) == "Player" and culprit.data.inWater) then
		if reason == HARM_TYPE_SPINJUMP and culprit.mount == 0 and culprit.character ~= CHARACTER_PEACH then
			finalHeight = jumpheights[culprit.character] - 10
		elseif culprit.mount == 0 then
			finalHeight = jumpheights[culprit.character]
		end
		
		Routine.run(function()
			Routine.skip()
			culprit:mem(0x11C,FIELD_WORD, finalHeight)
		end)
		
	end
end

function icantswim.onExit()
	for _,p in ipairs(Player.get()) do
		p.data.inWater = nil
		p.data.bubbleTimer = nil
		p.data.hasEnterSplashed = nil
		p.data.hasExitSplashed = nil
		p.data.bubbleTimer = nil
		p.data.justLeftWater = nil
	end
end

local function isOnGround(p) -- ripped straight from MrDoubleA's SMW Costume scripts
	return (
		p.speedY == 0 -- "on a block"
		or p:isGroundTouching() -- on a block (fallback if the former check fails)
		or p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
		or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
		or (p.mount == MOUNT_BOOT and p:mem(0x10C, FIELD_WORD) ~= 0) -- hopping around while wearing a boot
	)
end

local function canJump(p)
	return ( 
		p.mount ~= MOUNT_CLOWNCAR
		and p:mem(0x26,FIELD_WORD) == 0
	)
end

local function handleJumping(p,forceJump,playSFX) -- "replaces" the default SMBX jump with a replica that allows adjustable jumpheights
	if (p.mount ~= 0 and p.keys.altJump == KEYS_PRESSED) or (canJump(p) and (isOnGround(p) or forceJump) and (p.keys.jump or p.keys.altJump)) and p.data.inWater then
		Audio.sounds[1].muted = true
		Audio.sounds[33].muted = true
		if p.keys.altJump and p.mount == 0 -- lessens the jumpheight when spinjumping
		and p.character ~= CHARACTER_PEACH then 
			finalHeight = jumpheights[p.character] - 10
			p:mem(0x50,FIELD_BOOL, true)
			if playSFX then SFX.play(33) end
		elseif p.mount == 0 then
			finalHeight = jumpheights[p.character]
			if playSFX then SFX.play(1) end
		end
		
		Routine.run(function()
			Routine.skip()
			p:mem(0x11C,FIELD_WORD, finalHeight) -- this handles jumpheights (this trick doesn't affect springs :[ )
		end)
	end
end

function icantswim.spawnSplash(w)
	if icantswim.doSplash then
		for _,p in ipairs(Player.getIntersecting(currentBox.x, currentBox.y-16, currentBox.x+currentBox.width, currentBox.y+16)) do
			if p then
				Animation.spawn(icantswim.splashEffectID, p.x-24, currentBox.y-32)
			end
			if icantswim.doSplashSound then
				SFX.play(icantswim.splashSound)
			end
		end
	end
end

function icantswim.spawnBubble(o)
	if icantswim.doBubble then
		if RNG.randomInt(5) == 0 then
			Animation.spawn(icantswim.bubbleEffectID, (o.x+(o.width/2)+((o.width/4)*o.direction))-8, o.y+(o.height/2)-8)
		end
	end
end

function icantswim.onStart()
	for _,v in ipairs(Liquid.get()) do
		if v.isQuicksand == false then
			table.insert(waterBoxes, v)
			v.isHidden = true
		end
	end
end

function icantswim.onTick()
	for _,p in ipairs(Player.get()) do
		p.data.inWater = false
		p.data.bubbleTimer = p.data.bubbleTimer or 0
		p.data.hasEnterSplashed = p.data.hasEnterSplashed or false
		p.data.hasExitSplashed = p.data.hasExitSplashed or true
		p.data.bubbleTimer = p.data.bubbleTimer + 1
		
		Audio.sounds[1].muted = false
		Audio.sounds[33].muted = false
		
		for _,w in ipairs(waterBoxes) do
			if w.layer.isHidden == false then
				for _,plr in ipairs(Player.getIntersecting(w.x, w.y, w.x+w.width, w.y+w.height)) do
					currentBox = w
					plr.data.justLeftWater = true
					if plr.data.hasEnterSplashed == false then
						icantswim.spawnSplash()
						plr.data.hasEnterSplashed = true
					end
					plr.data.hasExitSplashed = false
					plr.data.inWater = true
					
					handleJumping(plr,false,true)
					if plr.speedY > 0 then
						plr.speedY = math.clamp(plr.speedY, Defines.gravity, 3)
					end
					if plr.keys.run or plr.keys.altRun then
						plr.speedX = math.clamp(plr.speedX, -icantswim.waterRunSpeed, icantswim.waterRunSpeed)
					else
						plr.speedX =  math.clamp(plr.speedX, -icantswim.waterRunSpeed / 2, icantswim.waterRunSpeed / 2)
					end
				end
				for _,n in ipairs(NPC.getIntersecting(w.x, w.y, w.x+w.width, w.y+w.height)) do
					n:mem(0x1C, FIELD_WORD, 3)
				end
			end
		end
		
		if p.data.inWater == true then
			if p.data.bubbleTimer >= 15 then
				icantswim.spawnBubble(p)
			end
		else
			if p.data.hasExitSplashed == false then
				icantswim.spawnSplash()
				p.data.hasExitSplashed = true
				p:mem(0x11C,FIELD_WORD,(p:mem(0x11C,FIELD_WORD)/2))
			end
			p.data.hasEnterSplashed = false
			
			if p.data.justLeftWater then
				p:mem(0x11C,FIELD_WORD, p:mem(0x11C,FIELD_WORD) - 20)
				if p.speedY < 0 then p.speedY = -6 end
				p.data.justLeftWater = nil
			end
		end

		for _,a in ipairs(bettereffects.getEffectObjects(icantswim.bubbleEffectID)) do
			p.data.inWater = false
			for _,b in ipairs(waterBoxes) do
				if ((a.x >= b.x and a.x <= b.x+b.width) and (a.y >= b.y and a.y <= b.y+b.height) and b.layer.isHidden == false)  then
					p.data.inWater = true
				end
			end
			if p.data.inWater == false then
				a.timer = 0
			end
		end
		
		if p.data.bubbleTimer >= 15 then
			p.data.bubbleTimer = 0
		end
	end
end

return icantswim