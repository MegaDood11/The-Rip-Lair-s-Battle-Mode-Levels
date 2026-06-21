local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local powBlock = {}
local blockIDs = {}

function powBlock.register(id, hits)
	blockManager.registerEvent(id, powBlock, "onTickBlock")
	blockManager.registerEvent(id, powBlock, "onDrawBlock")
	blockIDs[id] = hits
end

function powBlock.onInitAPI()
	registerEvent(powBlock, "onPostBlockHit")
end

function powBlock.onTickBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	
	local data = v.data
	local cfg = Block.config[v.id]
	
	if not data.initialized then
		data.hits = 0
		data.timer = 0
		data.initialized = true
	end

	if data.hits > 0 then
		data.timer = data.timer + 1
	else
		data.timer = 0
	end

	if data.timer % 450 == 0 then
		if data.hits > 0 then
			v:setSize(v.width, v.height + cfg.heightchange)
		end
		data.hits = math.max(data.hits - 1, 0)
	end
end

function powBlock.onPostBlockHit(v, fromUpper, playerOrNil)
	if not blockIDs[v.id] then return end
	
	local data = v.data
	local cfg = Block.config[v.id]
	local maxhits = blockIDs[v.id]

	if data.hits >= maxhits - 1 then
		return
	end
	
	if playerOrNil and not fromUpper then playerOrNil.speedY = 0 end
	
	Misc.doPOW()
	v:bump(fromUpper)
	v:setSize(v.width, v.height - cfg.heightchange)
	
	if v.contentID > 0 and data.hits == 0 then
		if v.contentID < 100 then
			for i = 1, v.contentID do
				local coin = NPC.spawn(10, v.x, v.y - 32)
				coin.speedX = RNG.random(-2, 2)
				coin.speedY = -4
				coin.ai1 = true
			end
		else
			local npc = NPC.spawn(v.contentID - 1000, v.x, v.y)
			npc.speedY = -4
		end
	end
	
	if maxhits > 0 then
		if data.hits < maxhits - 1 then
			data.hits = data.hits + 1
		end
	else
		data.hits = 1
	end
end

function powBlock.onDrawBlock(v)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) then return end
	local data = v.data
	
	local frameY = data.hits * 32
	if blockIDs[v.id] <= 0 then frameY = 0 end
	
	Graphics.draw{
		type = RTYPE_IMAGE,
		image = Graphics.sprites.block[v.id].img,
		x = v.x,
		y = v.y + v:mem(0x56, FIELD_WORD),
		sourceY = frameY,
		sourceHeight = v.height,
		priority = -65,
		sceneCoords = true
	}
	blockutils.setBlockFrame(v.id, -1)
end

return powBlock