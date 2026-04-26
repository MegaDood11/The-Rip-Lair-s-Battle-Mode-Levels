
local pitfall = {}

local img = Graphics.loadImageResolved("pitfall-particle.png")

local bgoIDs = table.map{}
local activeBGOS = {}

local effectTimer = 0

function pitfall.registerID(id)
	table.insert(bgoIDs,id)
end

local function getActiveBGOs()
	activeBGOS = {}
	for _,b in BGO.iterate(bgoIDs) do
		for i,section in ipairs(Section.getActive()) do
			local bounds = section.boundary
			if b.x >= bounds.left 
			and b.x + b.width <= bounds.right
			and b.y >= bounds.top
			and b.y + b.height <= bounds.bottom
			then
				table.insert(activeBGOS,b)
			end
		end
	end
end

function pitfall.onInitAPI()
	registerEvent(pitfall, "onStart")
	registerEvent(pitfall, "onWarp")
	registerEvent(pitfall, "onDraw")
end

function pitfall.onStart()
	getActiveBGOs()
end

function pitfall.onWarp(w,p)
	getActiveBGOs()
end

function pitfall.onDraw()
	for i,b in ipairs(activeBGOS) do
		if b.isValid and not b.isHidden then
			Graphics.drawBox{
				texture = img,
				x = b.x + b.width * 0.5,
				y = b.y + b.height * 0.5,
				width = img.width + effectTimer*2.5,
				height = img.height + effectTimer*2.5,
				color = (BGO.config[b.id].lightcolor or Color.white) .. 1 - (effectTimer * 0.03),
				priority = 0 + 0.01,
				sceneCoords = true,
				centered = true,
			}
		end
	end
	if not Misc.isPaused() then
		effectTimer = effectTimer + 1
		if effectTimer >= 28 then
			effectTimer = 0
		end
	end
end


return pitfall