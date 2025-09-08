--[[
	boneBlocks.lua - v1.1 by "Master" of Disaster
	
	A little thing I made - these weird Bone chain thingies from Mario U
	
	Very unspecial version for battle mode that slightly harms the player when hit by the wave

]]--

local battlePlayer = require("scripts/battlePlayer")

local boneBlocks = {
	--chainDelay = 5,		-- the delay in frames of each adjasoned block triggering
	--launchHeight = -10,	-- the speed of a block when hit
	--nocontroltimer = 0,	-- not really configurable, however you can edit them if necessary
	blockedNPCs = {		-- the ids of all npcs that should not be launched
		10, 11, 33, 46, 60, 62, 64, 66, 88, 91, 97, 103, 105, 106, 151, 152, 160, 192, 196, 197, 203, 204, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220,
		221, 222, 223, 224, 225, 226, 227, 251, 252, 253, 260, 289, 310, 378, 397, 398, 399, 400, 418, 423, 424, 430, 465, 528, 570, 582, 583, 591, 592, 593,
		594, 595, 596, 597, 598, 599, 600, 601, 602, 603,
	},

}

local cooldown = 200

local blockIDs = {}



local blockManager = require("blockManager")

local function revokeControl(p)		-- the player is not supposed to do any directional inputs
	p.keys.left = false
	p.keys.right = false
	p.keys.down = false
	p.keys.up = false
end

function boneBlocks.register(id)
	blockManager.registerEvent(id, boneBlocks, "onTickBlock")
	registerEvent(boneBlocks, "onPostBlockHit","onPostBlockHit",false)
	--blockManager.registerEvent(id, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
	blockIDs[id] = true
end
registerEvent(boneBlocks,"onTick")

function boneBlocks.onTick()
	for _,p in ipairs(Player.get()) do
		if not p.data.boneBlocks then
			p.data.boneBlocks = {nocontroltimer = 0}
		end
		if p.data.boneBlocks.nocontroltimer > 0 then
			p.data.boneBlocks.nocontroltimer = p.data.boneBlocks.nocontroltimer - 1
			revokeControl(p)
		end
	end
end

function boneBlocks.onTickBlock(v)
	local data = v.data
	
	if v.isHidden then return end

	if data.isHit == nil then	-- initialize all the variables used here
		data.isHit = false	-- if true, it got hit
		data.launchUp = false	-- if true, the block will get launched
		data.initialY = v.y
		data.launchSpeedY = 0
		data.cooldowntimer = 0	-- cooldown for when the block can be hit again
		data.offsettimer = 0		-- a timer that counts down and when it reaches 0, it gets launched
		data.triggerDir = 0		-- from which side did it get hit? (Used to bounce the player away)
		data.chainCollider = Colliders.Rect(0, 0, 1, 1, 0)
		data.bounceCollider = Colliders.Rect(0, 0, 1, 1, 0)
		--v.data.bounceCollider:debug(true)
	end
	
	data.chainCollider.x = v.x + v.width * 0.5
	data.chainCollider.y = v.y + v.height * 0.5
	data.chainCollider.width = v.width + 8
	data.chainCollider.height = v.height * 0.5
	
	data.bounceCollider.x = v.x + v.width * 0.5
	data.bounceCollider.y = v.y
	data.bounceCollider.width = v.width
	data.bounceCollider.height = v.height * 0.5
	
	--Text.print(v:mem(0x56,FIELD_WORD),100,100)
	
	if data.launchUp then
		if data.launchSpeedY <= 12 then
			data.launchSpeedY = data.launchSpeedY + 0.6	-- strong gravity moment
		end
		v.y = v.y + data.launchSpeedY
		
		if data.launchSpeedY > 0 then
			for _,p in ipairs(Player.get()) do
				if Colliders.collide(v,p) and p.y + p.height * 0.5 > v.y then
					p.y = p.y + data.launchSpeedY
				end
			end
		end
		
		if v.y > data.initialY then	-- back at original position
			data.isHit = false
			data.launchUp = false
			data.launchSpeedY = 0
			data.triggerDir = 0
			v.y = data.initialY
		end
		
		for _, n in ipairs(Colliders.getColliding{a = data.bounceCollider, btype = Colliders.NPC, filter = function(o) if not (o.isHidden or o.noblockcollision) then return true end end}) do
			if not table.contains(boneBlocks.blockedNPCs,n.id) then
				n.speedY = - 8
				n.y = n.y - 8
				Audio.playSFX(2)
			end
			--Misc.dialog("!")
		end
		for _,p in ipairs(Player.get()) do
			if Colliders.collide(data.bounceCollider,p) then
				battlePlayer.harmPlayer(p,battlePlayer.HARM_TYPE.SMALL_DAMAGE)	-- it'll just hurt a little
				p.speedY = - 8
				p.y = p.y - 8
				p.speedX = 6 * data.triggerDir
				p.data.boneBlocks.nocontroltimer = 20	-- disables controls for a moment
				Audio.playSFX(2)
			end
		end
	else
		data.initialY = v.y
	end
	
	if data.isHit then
		if data.cooldowntimer > 0 then			-- handles the cooldown, so they don't hit themselves in an endless loop
			data.cooldowntimer = data.cooldowntimer - 1
		else
			data.cooldowntimer = 0
			data.isHit = false
		end
		
		if data.offsettimer > 0 then				-- if it's hit by a chain reaction, count down the delay and only then launch it!
			data.offsettimer = data.offsettimer - 1
		elseif v.data.offsettimer <= 0 and not data.launchUp then
			data.offsettimer = 0
			data.launchUp = true
			data.launchSpeedY = Block.config[v.id].launchHeight
			v:hit()
		end
	end
end

function boneBlocks.onPostBlockHit(b, fromAbove, p)
	--Misc.dialog(b,fromAbove,p)
	if blockIDs[b.id] then
		--Misc.dialog(b.x)
		b.data.isHit = true
		b.data.cooldowntimer = cooldown
		for _, v in ipairs(Colliders.getColliding{a = b.data.chainCollider, btype = Colliders.BLOCK, filter = function(o) if not o.isHidden and blockIDs[o.id] and not o.data.isHit and o:mem(0x56,FIELD_WORD) == 0 then return true end end}) do
			v.data.offsettimer = Block.config[v.id].chainDelay
			v.data.isHit = true
			v.data.cooldowntimer = cooldown
			if v.x + v.width * 0.5 - b.x - b.width * 0.5 > 0 then
				v.data.triggerDir = 1	-- moving to the right
			else
				v.data.triggerDir = -1	-- moving to the left
			end
			--v.y = v.y - 100
		end
	end
end


return boneBlocks