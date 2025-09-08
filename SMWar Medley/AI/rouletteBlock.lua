--[[
	rouletteBlock.lua v1.1 by "Master" of Disaster
	
	A block that cycles through it's options, and releases the currently highlighted npc when hit!
	remember to credit if used, I can't think of a dumb casino joke going alongside this mention
]]--


local rouletteBlock = {

}

local rouletteIDs = {}

local blockManager = require("blockManager")

registerEvent(rouletteBlock,"onTick")
registerEvent(rouletteBlock,"onBlockHit")

function rouletteBlock.register(id)
	blockManager.registerEvent(id, rouletteBlock, "onTickEndBlock")
	blockManager.registerEvent(id, rouletteBlock, "onDrawBlock")
	rouletteIDs[id] = true
end

function rouletteBlock.onTickEndBlock(v)

	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	
	if not data.rouletteInitialized then	-- initializes all the important data
		data.rouletteInitialized = true
		data.isEmpty = false	-- if true, it won't cycle anymore.
		data.prevID = v.id		-- so the block can change back to it's proper id
		data.prevWidth = v.width
		data.prevHeight = v.height
		data.cycletimer = 0		-- counts up. If it reaches a set threshold it switches to the next powerup
		data.cyclepos = 1		-- at which position of the cycle it's currently
		if not data._settings.contentList[1] then
			data.isEmpty = true
		else
			v.contentID = 1000 + data._settings.contentList[1].id
		end
	end
	
	if data.isEmpty then return end
	
	if data.cycletimer < data._settings.cycletime then
		data.cycletimer = data.cycletimer + 1
	else
		data.cycletimer = 0
		if data.cyclepos < table.maxn(data._settings.contentList) then
			data.cyclepos = data.cyclepos + 1
		else
			data.cyclepos = 1
		end
		v.contentID = 1000 + data._settings.contentList[data.cyclepos].id
	end
	
end

function rouletteBlock.onTick()
	for k, v in Block.iterate(2) do
		if v.data.wasRouletteBlock then
			v.data.isEmpty = true
			--v.x = v.x + (v.data.prevWidth - v.width) * 0.5
			v.y = v.y + (v.data.prevHeight - v.height) * 0.5
			v:transform(v.data.prevID,true)
		end
	end
end

function rouletteBlock.onBlockHit(event, v, fromUpper, p)	-- make sure to release the powerup as is
	if rouletteIDs[v.id] then
		if p and p.powerup == 1 and not v.data.isEmpty then
			p.powerup = 2
			v:hit(fromUpper,p)
			p.powerup = 1
			event.cancelled = true
		elseif not p and not v.data.isEmpty and not v.data.isHitRemotely then	-- ugly check for when the block is hit via projectile
			for _,p in ipairs(Player.get()) do
				if p.powerup == 1 then
					p.powerup = 2
					v:hit(fromUpper,nil)
					p.powerup = 1
					v.data.isHitRemotely = true
					event.cancelled = true
				end
			end
		end
		
	end
end

function rouletteBlock.onDrawBlock(v)
	local data = v.data
	if v.isHidden or not data.rouletteInitialized then return end
	if data.isEmpty then return end
	

	local contentID = data._settings.contentList[data.cyclepos].id
	local npcsprite = Graphics.loadImageResolved("npc-".. contentID .. ".png")
	local contentWidth = NPC.config[contentID].gfxWidth
	local contentHeight = NPC.config[contentID].gfxHeight
	
	if contentWidth == 0 and contentHeight == 0 then	-- failsave for non-X2 NPCs (they don't necessarily have npc configs)
		contentWidth = npcsprite.width
		contentHeight = npcsprite.width
	end
	
	Graphics.drawBox{							-- draw the npc contained within
		texture      = npcsprite,
		sceneCoords  = true,
		x            = v.x + v.width * 0.5,
		y            = v.y + v.height * 0.5,
		width        = 32,
		height       = 32,
		sourceX      = 0,
		sourceY      = 0,
		sourceWidth  = contentWidth,
		sourceHeight = contentHeight,
		centered     = true,
		priority     = Block.config[v.id].contentPriority,
		color        = Color.white .. 1,
		rotation     = 0,		
	}
end

return rouletteBlock