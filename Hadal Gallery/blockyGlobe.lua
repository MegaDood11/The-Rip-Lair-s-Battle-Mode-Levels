local globalBlock = {}

local blockList = {}
local isGlobal = false

local function checkData(data)
	local hasGlobalSettings = false
	
	for k,v in pairs(data) do
		if k:find('_blockyGlobe') then
			hasGlobalSettings = true
			break
		end
	end
	
	return hasGlobalSettings
end

local redraw = {}

local _initialized = {}

local function getData(v)
	if isGlobal then
		return v.data._settings._global
	end
	
	return v.data._settings
end

local initializeSettings

do
	-- initialize fields and etc...
	
	local function isInitialized(v)
		return _initialized[v.idx]
	end

	local function initialize(v)
		_initialized[v.idx] = true
	end

	initializeSettings = function(v, data)
		local addToList = false
			
		if not isInitialized(v) then
			data.timer_blockyGlobe = 0
			
			data.originX_blockyGlobe = v.x
			data.originY_blockyGlobe = v.y
			
			data.movement_blockyGlobe = data.movement_blockyGlobe or ""
			
			if data.movement_blockyGlobe ~= "" then
				local input = [[
					return function(block, x, y, t, sin, cos, tan) 
						return {]] .. data.movement_blockyGlobe .. [[} 
					end
				]]
				
				local chunk, err = load(input)
				
				if err then
					return error(err)
				end
				
				if chunk then
					addToList = true
					data.movement_blockyGlobe = chunk()
				end
			end
			
			if data.priority_blockyGlobe > -102 then
				addToList = true
				redraw[v.idx] = {priority = data.priority_blockyGlobe}
			end
			
			if data.isSizable_blockyGlobe then
				addToList = true
				redraw[v.idx] = redraw[v.idx] or {}
				redraw[v.idx].sizable = true
			end
			
			if data.stretch_blockyGlobe then
				addToList = true
				redraw[v.idx] = redraw[v.idx] or {}
				redraw[v.idx].stretch = true
			end
			
			if data.repeat_blockyGlobe then
				addToList = true
				redraw[v.idx] = redraw[v.idx] or {}
				redraw[v.idx].repeating = true
			end
			
			if data.width_blockyGlobe > 0 then
				v.width = data.width_blockyGlobe
			end
			
			if data.height_blockyGlobe > 0 then
				v.height = data.height_blockyGlobe
			end
			
			initialize(v)
		end
		
		return addToList
	end
end

function globalBlock.onStart()
	for k,v in Block.iterate() do
		if k == 1 then
			local data = v.data
			
			-- Check if blocks have global settings...
			local result = checkData(data._settings)
			
			if not result then
				isGlobal = true
			end
		end
		
		local addToList = initializeSettings(v, getData(v))
		
		if addToList then
			blockList[#blockList + 1] = v
		end
	end
end

local sin = math.sin
local cos = math.cos
local tan = math.tan

local function translate(v, data, x, y)
	local ox, oy = -v.x, -v.y
	
	ox = ox + data.originX_blockyGlobe
	oy = oy + data.originY_blockyGlobe
	
	v:translate(ox + x, oy + y) 
	
	return ox + x, oy + y
end

local function movement(v, data)
	local data = getData(v)
	
	local timer = data.timer_blockyGlobe
	local settings = data.movement_blockyGlobe(v, v.x, v.y, lunatime.toSeconds(timer), 
	sin, cos, tan)
	
	settings.x = settings.x or 0
	settings.y = settings.y or 0
	
	v.extraSpeedX = settings.extraSpeedX or v.extraSpeedX
	v.extraSpeedY = settings.extraSpeedY or v.extraSpeedY
	v.speedX = settings.speedX or v.speedX
	v.speedY = settings.speedY or v.speedY
			
	translate(v, data, settings.x, settings.y)
end

local nocollision = {}

local function onTick(v)
	local data = getData(v)
	
	data.timer_blockyGlobe = data.timer_blockyGlobe + 1
	
	if type(data.movement_blockyGlobe) == 'function' then
		movement(v, data)
	end
	
	if data.nocollision_blockyGlobe then
		nocollision[v.idx] = true
		v.isHidden = true
	end
end

local function onTickEnd(v)
	local data = getData(v)
	
	if nocollision[v.idx] then
		local l = Layer.get(v.layerName)
		v.isHidden = l.isHidden
		
		nocollision[v.idx] = nil
	end
end

function globalBlock.onTick()
	for k = 1, #blockList do
		onTick(blockList[k])
	end
end

function globalBlock.onTickEnd()
	for k = 1, #blockList do
		onTickEnd(blockList[k])
	end
end

local hide = {}
local invisible = {}

local function onDraw(v)
	if redraw[v.idx] then
		if v.invisible then
			invisible[v.idx] = true
		end
		
		v.invisible = true
		
		hide[#hide + 1] = {obj = v, data = redraw[v.idx]}
	end
end

function globalBlock.onDraw()
	for k = 1, #blockList do
		onDraw(blockList[k])
	end
end

local blockutils = require 'blocks/blockutils'
local sizable = require 'game/sizable'

local ceil = math.ceil

local function repeatingBlock(v, image, cfg, f, priority, cam)
	local iterate_w = ceil((v.width / cfg.width) + 0.5)
	local iterate_h = ceil((v.height / cfg.height) + 0.5)

	for ow = 1, iterate_w do
		for oh = 1, iterate_h do
			local x = cfg.width * (ow - 1)
			local y = cfg.height * (oh - 1)
			
			local w = cfg.width
			local h = cfg.height
			
			if ow == iterate_w then
				w = v.width % cfg.width
			end
			
			if oh == iterate_h then
				h = v.height % cfg.height
			end
			
			Graphics.drawImageToSceneWP(image, v.x + x, v.y + y, 0, f, w, h, priority)
		end
	end
end

local function renderBlock(v, data, cam)
	if not blockutils.visible(cam, v.x, v.y, v.width, v.height) then return end
	
	local cfg = Block.config[v.id]
	
	local priority = data.priority
	
	if priority == nil then
		priority = (cfg.lava and -10) or -65
	end
	
	local image = Graphics.sprites.block[v.id].img
	local frame = blockutils.getBlockFrame(v.id) * cfg.height
		
	if data.stretch then
		return Graphics.drawBox{
			texture = image,
			
			x = v.x,
			y = v.y,
			
			sourceY = frame * cfg.height,
			
			sourceWidth = cfg.width,
			sourceHeight = cfg.height,
			
			width = v.width,
			height = v.height,
			
			priority = priority,
			sceneCoords = true,
		}
	end
	
	if cfg.sizable or data.sizable then
		v.invisible = false
		sizable.drawSizable(v, cam, priority)
		v.invisible = true
	else
		if data.repeating and (v.width > cfg.width or v.height > cfg.height) then
			return repeatingBlock(v, image, cfg, frame, priority, cam)
		end
		
		Graphics.drawImageToSceneWP(image,v.x,v.y,0,frame,v.width,v.height, priority)
	end
end

function globalBlock.onCameraDraw(idx)
	for k = 1, #hide do
		local v = hide[k]

		renderBlock(v.obj, v.data, Camera(idx))
	end
end

function globalBlock.onDrawEnd()
	for k = 1, #hide do
		local v = hide[k]
		v = v.obj
		
		v.invisible = invisible[v.idx] or false
		
		hide[k] = nil
	end
end

function globalBlock.onInitAPI()
	registerEvent(globalBlock, 'onStart')
	
	registerEvent(globalBlock, 'onTick')
	registerEvent(globalBlock, 'onTickEnd')
	
	registerEvent(globalBlock, 'onDraw')
	registerEvent(globalBlock, 'onCameraDraw')
	registerEvent(globalBlock, 'onDrawEnd')
end

return globalBlock