--------------------------------------------------
-- Level code
-- Created 18:19 2025-7-28
--------------------------------------------------

local battleGeneral = require("scripts/battleGeneral")
local onlinePlay = require("scripts/onlinePlay")

battleTimer = require("scripts/battleTimer")
battleOptions = require("scripts/battleOptions")

local doormode = onlinePlay.createVariable("doormode","uint16",true,0)
local doorlay = onlinePlay.createVariable("doorlay","uint16",true,0)
local doormake = onlinePlay.createVariable("doormake","uint16",true,0)

local dojoe = onlinePlay.createVariable("dojoe","uint16",true,0)

local doorsolidA = onlinePlay.createVariable("doorsolidA","uint16",true,0)
local doorsolidB = onlinePlay.createVariable("doorsolidB","uint16",true,0)
local doorwarpA = onlinePlay.createVariable("doorwarpA","uint16",true,0)
local doorwarpB = onlinePlay.createVariable("doorwarpB","uint16",true,0)

local joenorm = {}
local joeahh = {}

local crounda1 = {}
local croundb1 = {}
local crounda2 = {}
local croundb2 = {}
local crounda3 = {}
local croundb3 = {}
local croundbow = onlinePlay.createVariable("croundbow","uint16",true,0)
local croundpos = onlinePlay.createVariable("croundpos","uint16",true,0)

local lan1 = {}
local lan2 = {}
local lan3 = {}
local lan4 = {}
local lan5 = {}
local lan6 = {}
local lant = onlinePlay.createVariable("lant","uint16",true,0)

-- Run code on level start
function onStart()
    doorsolidA = Layer.get("doorsolidA")
	doorsolidB = Layer.get("doorsolidB")
	doorwarpA = Layer.get("doorwarpA")
	doorwarpB = Layer.get("doorwarpB")
	
	joenorm = Layer.get("joenorm")
	joeahh = Layer.get("joeahh")
	
	doormake = true
	dojoe = false
	
	crounda1 = Layer.get("crounda1")
	croundb1 = Layer.get("croundb1")
	crounda2 = Layer.get("crounda2")
	croundb2 = Layer.get("croundb2")
	crounda3 = Layer.get("crounda3")
	croundb3 = Layer.get("croundb3")
	croundbow = math.random(0,1)
	croundpos = math.random(0,2)
	
	if croundbow == 0 then
		crounda1:show(true)
		crounda2:show(true)
		crounda3:show(true)
	end
	if croundbow == 1 then
		croundb1:show(true)
		croundb2:show(true)
		croundb3:show(true)
	end
	if croundpos == 0 then
		crounda2:hide(true)
		croundb2:hide(true)
		crounda3:hide(true)
		croundb3:hide(true)
	end
	if croundpos == 1 then
		crounda1:hide(true)
		croundb1:hide(true)
		crounda3:hide(true)
		croundb3:hide(true)
	end
	if croundpos == 2 then
		crounda1:hide(true)
		croundb1:hide(true)
		crounda2:hide(true)
		croundb2:hide(true)
	end
	
	lant = 0
	lan1 = Layer.get("lan1")
	lan2 = Layer.get("lan2")
	lan3 = Layer.get("lan3")
	lan4 = Layer.get("lan4")
	lan5 = Layer.get("lan5")
	lan6 = Layer.get("lan6")
	
	Routine.run(function ()
		for i = 0,20,1 do
			lant = math.random(0, 5)
			lan1:hide(true)
			lan2:hide(true)
			lan3:hide(true)
			lan4:hide(true)
			lan5:hide(true)
			lan6:hide(true)
			if lant == 0 then
				lan1:show(true)
			end
			if lant == 1 then
				lan2:show(true)
			end
			if lant == 2 then
				lan3:show(true)
			end
			if lant == 3 then
				lan4:show(true)
			end
			if lant == 4 then
				lan5:show(true)
			end
			if lant == 5 then
				lan6:show(true)
			end
			Routine.waitSeconds(30)
		end
	end)
end

-- Run code every frame (~1/65 second)
-- (code will be executed before game logic will be processed)
function onTick()
    for k,v in ipairs(Block.get(2)) do
		v:setSize(40,40)
	end
	for k,v in ipairs(Block.get(282)) do
		v:setSize(40,40)
	end
	for k,v in ipairs(Block.get(283)) do
		v:setSize(40,40)
	end
	if doormake == true then
		Routine.run(function ()
			doormode = math.random(0, 1)
			doorlay = math.random(15, 120)
			doormake = false
			Routine.waitSeconds(doorlay)
			if doormode == 0 then
				doorsolidA:show(true)
				doorwarpA:show(true)
			end
			if doormode == 1 then
				doorsolidB:show(true)
				doorwarpB:show(true)
			end
		end)
	end
end

-- Run code when internal event of the SMBX Engine has been triggered
-- eventName - name of triggered event
function onEvent(eventName)
    if eventName == "joeslifesavings" then
		Routine.run(function ()
			joenorm:hide(true)
			joeahh:show(true)
			Routine.waitSeconds(60)
			joenorm:show(true)
			joeahh:hide(true)
		end)
		
	end
end

function onWarp(w,p)
	doorsolidA:hide(true)
	doorsolidB:hide(true)
	SFX.play("gaster-vanish.mp3")
	doormake = true
end

function onWarpEnter(e,w,p)
	doorwarpA:hide(true)
	doorwarpB:hide(true)
end