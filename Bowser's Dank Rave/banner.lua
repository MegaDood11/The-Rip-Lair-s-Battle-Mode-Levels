local verlet = require("verletrope2")

local banner = {}

banner.presets = {}

--[[
preset must be a table
- clothTex
- clothWidth
- clothHeight
- divisions
- doodadTex
- poleTex
--]]
function banner.registerPreset(id, preset)
	banner.presets[id] = preset
end

local function gridGet(grid, x, y) 
	local index = (x-1) * grid.width + (y-1) + 1
	
	return grid[index]
end

local function drawBannerData(bannerData, npc)
	local preset = bannerData.preset
	
	local cloth = bannerData.cloth
	local clothGrid = bannerData.clothGrid

	local vertices = {}
	local uvs = {}
	
	local vertindex = 1
	local ustep = 1 / (clothGrid.width - 1)
	local vstep = 1 / (clothGrid.height - 1)
	for x = 1, clothGrid.width - 1 do
		for y = 1, clothGrid.height - 1 do
			local p1 = clothGrid:get(x, y).position
			local p2 = clothGrid:get(x+1, y).position
			local p3 = clothGrid:get(x, y+1).position
			local p4 = clothGrid:get(x+1, y+1).position
			
			local u1 = (x-1) * ustep
			local u2 = (x) * ustep
			local v1 = (y-1) * vstep
			local v2 = (y) * vstep
			
			vertices[vertindex + 0] = p1.x
			vertices[vertindex + 1] = p1.y
			vertices[vertindex + 2] = p2.x
			vertices[vertindex + 3] = p2.y
			vertices[vertindex + 4] = p3.x
			vertices[vertindex + 5] = p3.y
			
			vertices[vertindex + 6] = p2.x
			vertices[vertindex + 7] = p2.y
			vertices[vertindex + 8] = p4.x
			vertices[vertindex + 9] = p4.y
			vertices[vertindex + 10] = p3.x
			vertices[vertindex + 11] = p3.y
			
			uvs[vertindex + 0] = u1
			uvs[vertindex + 1] = v1 -- p1
			uvs[vertindex + 2] = u2
			uvs[vertindex + 3] = v1 -- p2
			uvs[vertindex + 4] = u1
			uvs[vertindex + 5] = v2 -- p3
			
			uvs[vertindex + 6] = u2 -- p2
			uvs[vertindex + 7] = v1
			uvs[vertindex + 8] = u2 -- p4
			uvs[vertindex + 9] = v2
			uvs[vertindex + 10] = u1 -- p3
			uvs[vertindex + 11] = v2
			
			vertindex = vertindex + 12
		end
	end
	
	if(preset.poleTex) then
		for y = 0, math.abs(bannerData.offsetY), preset.poleTex.height do
			Graphics.drawImageToSceneWP(
				preset.poleTex,
				bannerData.originX - preset.poleTex.width / 2,
				bannerData.originY + math.min(0, bannerData.offsetY) + y,
				0,
				0,
				preset.poleTex.width,
				math.min(math.abs(bannerData.offsetY) - y),
				-47
			)
		end
	end
	
	if(preset.doodadTex) then 
		Graphics.drawImageToSceneWP(
			preset.doodadTex,
			bannerData.originX - preset.doodadTex.width / 2,
			bannerData.originY + bannerData.offsetY - preset.doodadTex.height / 2,
			-47
		)
	end
	
	Graphics.glDraw{
		vertexCoords = vertices,
		textureCoords = uvs,
		texture = preset.clothTex,
		priority = -47,
		sceneCoords = true
	}
end

local function updateBannerData(bannerData)
	local preset = bannerData.preset
	local strandCount = #bannerData.cloth.strands
	for i, strand in ipairs(bannerData.cloth.strands) do
		strand.segments[1].position = vector(bannerData.originX + ((i - 1) / (strandCount - 1)) * preset.clothWidth - preset.clothWidth / 2, bannerData.originY + bannerData.offsetY)
	end

	bannerData.cloth:update()
end

function banner.setup(npc, presetID, offsetY)
	local data = npc.data
	local preset = banner.presets[presetID]
	
	if(preset == nil) then error("invalid banner preset "..presetID) end
	
	local bannerData = {}
	
	bannerData.preset = preset
	bannerData.cloth = verlet.Cloth(vector(npc.x, npc.y), vector(npc.x + preset.clothWidth, npc.y), vector(npc.x, npc.y + preset.clothHeight), vector(npc.x + preset.clothWidth, npc.y + preset.clothHeight), preset.divisions, 10, Defines.npc_grav * 2, true)
	bannerData.update = updateBannerData
	bannerData.draw = drawBannerData
	bannerData.originX = npc.x
	bannerData.originY = npc.y
	bannerData.offsetY = offsetY or 0
	
	bannerData.clothGrid = {}
	
	for _, strand in ipairs(bannerData.cloth.strands) do
		for _, segment in ipairs(strand.segments) do
			table.insert(bannerData.clothGrid, segment)
		end
	end
	
	bannerData.clothGrid.get = gridGet
	bannerData.clothGrid.height = #(bannerData.cloth.strands[1].segments)
	bannerData.clothGrid.width = #(bannerData.cloth.strands)
	
	data.bannerData = bannerData
	
	return bannerData
end



return banner