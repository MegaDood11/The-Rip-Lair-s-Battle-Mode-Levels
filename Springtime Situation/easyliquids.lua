-- ------------------------------
-- easyliquids.lua 
-- by Akromaly
-- v1.0
-- ------------------------------

local transition = require("transition")

local easyliquids = {}

local frame = 0

easyliquids.levelLiquids = {}

-- type constants
easyliquids.TYPE_WATER = 1
easyliquids.TYPE_LAVA = 2

-- style constants
easyliquids.STYLE_SMB = 1
easyliquids.STYLE_SMB3 = 2
easyliquids.STYLE_SMW = 3
easyliquids.STYLE_SMM2 = 4

local liquidTables = {}
local liquidObjs = {}

local IMMUNE_NPCS = {11, 16, 17, 18, 33, 38, 41, 42, 43, 44, 46, 56, 57, 91, 97, 103, 105, 106, 138, 151, 152, 159, 196, 197, 199, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 251, 252, 253, 255, 256, 257, 258, 259, 274, 294, 298, 299, 310, 322, 323, 324, 333, 334, 335, 336, 337, 338, 339, 341, 342, 343, 344, 361, 362, 364, 367, 370, 378, 387, 391, 397, 398, 399, 400, 411, 418, 419, 420, 421, 422, 423, 424, 428, 429, 430, 444, 465, 469, 473, 476, 477, 478, 479, 480, 481, 482, 483, 484, 528, 533, 534, 535, 536, 552, 553, 554, 555, 556, 557, 570, 572, 582, 583, 584, 585, 586, 589, 590, 591, 592, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 625, 626, 636, 638, 639, 668, 669, 670, 671, 672, 673, 674}
local SOLID_ON_LAVA = {58, 67, 68, 69, 70, 78, 79, 80, 81, 82, 83, 160, 190, 191, 263, 297, 355, 358, 393, 413, 438, 439, 440, 441, 442, 443, 445}

local liquidStyles = {
	[easyliquids.TYPE_WATER] = {
		[easyliquids.STYLE_SMM2] = {
			bgoID      = 751,
			frames     = 4,
			framespeed = 8,
			priority   = -10,
			opacity    = 1
		},
		[easyliquids.STYLE_SMW] = {
			bgoID      = 264,
			frames     = 4,
			framespeed = 8,
			priority   = -85,
			opacity    = 1
		},
		[easyliquids.STYLE_SMB3] = {
			bgoID      = 82,
			frames     = 4,
			framespeed = 8,
			priority   = -10,
			opacity    = 0.6
		},
		[easyliquids.STYLE_SMB] = {
			bgoID      = 168,
			frames     = 8,
			framespeed = 8,
			priority   = -10,
			opacity    = 0.6
		}
	},

	[easyliquids.TYPE_LAVA] = {
		[easyliquids.STYLE_SMM2] = {
			blockID    = 404,
			frames     = 4,
			framespeed = 8,
			priority   = -10,
			opacity    = 1,
			glowcolor  = Color.red
		},
		[easyliquids.STYLE_SMW] = {
			blockID    = 459,
			frames     = 4,
			framespeed = 8,
			priority   = -10,
			opacity    = 1,
			glowcolor  = Color.red
		},
		[easyliquids.STYLE_SMB3] = {
			blockID    = 30,
			frames     = 4,
			framespeed = 8,
			priority   = -10,
			opacity    = 1,
			glowcolor  = Color.red
		},
		[easyliquids.STYLE_SMB] = {
			blockID    = 371,
			frames     = 8,
			framespeed = 8,
			priority   = -10,
			opacity    = 1,
			glowcolor  = Color.red
		}
	}
}

local liquidTextures = {}
local lavaTexture

-- ## LOCAL METHODS

-- Spawns a vanilla liquid zone
local function spawnLiquid(x, y, width, height, quicksand)
	writemem(0x00B25700, FIELD_WORD, Liquid.count() + 1)
	local newLiquid = Liquid(Liquid.count())
  
	newLiquid.layerName = "Default"
	newLiquid.isHidden = false
	writemem(newLiquid._ptr + 0x08, FIELD_FLOAT, 0)
	if quicksand then
	  newLiquid.isQuicksand = true
	else
	  newLiquid.isQuicksand = false
	end
	newLiquid.x = x
	newLiquid.y = y
	newLiquid.width = width
	newLiquid.height = height
	newLiquid.speedX = 0
	newLiquid.speedY = 0
	
	return newLiquid
end

-- Liquid drawing handling 
local function drawLiquid(liquid)
	local size = liquid.bounds.right - liquid.bounds.left
	local liquidLevel = liquid.bounds.bottom - liquid.height
	local framesize = liquidTextures[liquid.liquidtype][liquid.style].height / liquidStyles[liquid.liquidtype][liquid.style].frames

	-- surface sprite
	for i = 0, math.floor(size / liquidTextures[liquid.liquidtype][liquid.style].width) do
		Graphics.draw({
			type = RTYPE_IMAGE,
			image = liquidTextures[liquid.liquidtype][liquid.style],
			sceneCoords = true,
			x = liquid.bounds.left + i * liquidTextures[liquid.liquidtype][liquid.style].width,
			y = liquidLevel,
			sourceX = 0,
			sourceY = framesize * frame,
			sourceWidth = liquidTextures[liquid.liquidtype][liquid.style].width,
			sourceHeight = framesize,
			priority = liquidStyles[liquid.liquidtype][liquid.style].priority + 1,
			opacity = liquidStyles[liquid.liquidtype][liquid.style].opacity
		})

	end
	
	-- uses the bottom pixel color of the sprite to fill the rest of the area
	Graphics.drawBox({
		sceneCoords = true,
		priority = liquidStyles[liquid.liquidtype][liquid.style].priority,
		x = liquid.bounds.left,
		y = liquidLevel + framesize,
		w = size,
		h = liquid.bounds.bottom - liquidLevel,
		texture = liquidTextures[liquid.liquidtype][liquid.style],
		sourceY = liquidTextures[liquid.liquidtype][liquid.style].height,
		sourceWidth = 1,
		sourceHeight = 1,
		color = Color.white .. liquidStyles[liquid.liquidtype][liquid.style].opacity
	})

end

for name, func in pairs(require("ext/easing")) do
	easyliquids["EASING_"..name:upper()] = func
end

-- ## ERROR HANDLING

local function is_integer(val)
	return type(val) == "number" and math.floor(val) == val
end


local function liquid_error_handling(section, args)

	if not section then
		error("Missing section argument for liquid.")
	elseif not is_integer(section) or section > 20 then
		error("Invalid section argument for liquid: '" .. section .. "'.")
	end

	if args.liquidtype and (not is_integer(args.liquidtype) or args.liquidtype < 1 or args.liquidtype > 2) then
		error("Invalid liquid type in section " .. section .. ".")
	end

	if args.style and (not is_integer(args.style) or not liquidStyles[args.liquidtype or 1][args.style]) then
		error("Invalid liquid style in section " .. section .. ".")
	end

	if not liquidTextures[args.liquidtype or 1][args.style or 4] then
		error("Missing liquid graphic in section " .. section .. ".")
	end

	if args.blockheight == nil and args.height == nil then
		error("Missing liquid height in section " .. section .. ".")
	elseif args.blockheight and type(args.blockheight) ~= "number" then
		error("Invalid liquid block height in section " .. section .. ".")
	elseif args.height and type(args.height) ~= "number" then
		error("Invalid liquid height in section " .. section .. ".")
	end

	if args.targetheight and type(args.targetheight) ~= "number" then
		error("Invalid liquid target height in section " .. section .. ".")
	end

	if args.targetblockheight and type(args.targetblockheight) ~= "number" then
		error("Invalid liquid target block height in section " .. section .. ".")
	end

	if args.movetime and (type(args.movetime) ~= "number" or args.movetime < 0) then
		error("Invalid liquid move time in section " .. section .. ".")
	end

	if args.waittime and (type(args.waittime) ~= "number" or args.waittime < 0) then
		error("Invalid liquid wait time in section " .. section .. ".")
	end

	if args.easing and type(args.easing) ~= "function" then
		error("Invalid liquid easing function in section " .. section .. ".")
	end

	if args.goback and type(args.goback) ~= "boolean" then
		error("Not boolean 'goback' value for liquid in section " .. section .. ".")
	end

end

local function movement_error_handling(section, newHeight, seconds, easing, waittime)
	if not section then
		error("Missing section argument for liquid movement.")
	elseif not is_integer(section) or section > 20 then
		error("Invalid section argument for liquid movement: '" .. section .. "'.")
	end

	if not newHeight then
		error("Missing new height for liquid movement.")
	elseif type(newHeight) ~= "number" then
		error("Invalid new height for liquid movement in section " .. section .. ".")
	end

	if seconds and (type(seconds) ~= "number" or seconds < 0) then
		error("Invalid duration for liquid movement in section " .. section .. ".")
	end

	if easing and type(easing) ~= "function" then
		error("Invalid easing function for liquid movement in section " .. section .. ".")
	end

	if waittime and (type(waittime) ~= "number" or waittime < 0) then
		error("Invalid wait time for liquid movement in section " .. section .. ".")
	end

end

local function style_error_handling(args)

	if args.liquidtype and (not is_integer(args.liquidtype) or args.liquidtype > 2) then
		error("Invalid style type for liquid.")
	end
	
	if args.liquidtype == easyliquids.TYPE_LAVA then
		if not args.blockID then
			error("Missing Block ID for lava style.")
		elseif not is_integer(args.blockID) or not Misc.resolveGraphicsFile("block-" .. tostring(args.blockID) .. ".png") then
			error("Invalid Block ID for lava style.")
		end

		if args.glowcolor and type(args.glowcolor) ~= "Color" then
			error("Invalid glow color for lava style.")
		end
	else
		if not args.bgoID then
			error("Missing BGO ID for water style.")
		elseif not is_integer(args.bgoID) or not Misc.resolveGraphicsFile("background-" .. tostring(args.bgoID) .. ".png") then
			error("Invalid BGO ID for water style.")
		end
	end

	if args.priority and type(args.priority) ~= "number" then
		error("Invalid priority for liquid style.")
	end

	if args.opacity and (type(args.priority) ~= "number" or args.priority > 1 or args.priority < 0) then
		error("Invalid opacity for liquid style.")
	end

	if args.frames and (not is_integer(args.frames) or args.frames <= 0) then
		error("Invalid frame number for liquid style.")
	end

	if args.framespeed and (not is_integer(args.framespeed) or args.framespeed <= 0) then
		error("Invalid frame speed for liquid style.")
	end
end

-- internal function to handle liquid movement
local function setLiquidPosition(liquidTable, newHeight, ticks, easing, waittime)

	if liquidTable then
	
		local waterOffset = 0

		if ticks == 0 then

			transition.clear(liquidTable)

			liquidTable.height = newHeight

			if liquidTable.liquidtype == easyliquids.TYPE_LAVA then
				liquidTable.light.y = liquidTable.bounds.bottom - newHeight + newHeight * 0.5
				liquidTable.light.height = newHeight
			end

			liquidObj = liquidObjs[liquidTable.section]

			if liquidObj then
				transition.clear(liquidObj)

				liquidObj.y = liquidTable.bounds.bottom - newHeight + waterOffset
				liquidObj.height = newHeight - waterOffset
			end

		else
			local r = Routine.run(
				function()

					liquidTable.movements = liquidTable.movements + 1
					local n = liquidTable.movements
					local sgnl = {liquidTable.section, liquidTable.movements}
					table.insert(liquidTable.signals, sgnl)
					
					if liquidTable.moving and #liquidTable.signals > 1 then
						Routine.waitSignal(liquidTable.signals[#liquidTable.signals - 1], true)
					end
					

					liquidTable.moving = true
					
					if liquidTable.liquidtype == easyliquids.TYPE_WATER then
						waterOffset = 16
					end

					liquidObj = liquidObjs[liquidTable.section]

					if liquidObj then
						transition.to(liquidObj, math.floor(ticks), easing, {y = liquidTable.bounds.bottom - newHeight + waterOffset, height = newHeight - waterOffset})
					end

					transition.to(liquidTable, math.floor(ticks), easing, {height = newHeight})

					if liquidTable.liquidtype == easyliquids.TYPE_LAVA then
						transition.to(liquidTable.light, math.floor(ticks), easing, {y = liquidTable.bounds.bottom - newHeight + newHeight * 0.5, height = newHeight})
					end

					Routine.waitFrames(math.floor(ticks + waittime))
					table.remove(liquidTable.signals, 1)
					Routine.signal(sgnl)
					liquidTable.moving = false
				end
			)
		end
	end
end

-- ## PUBLIC METHODS

-- Deletes the liquid in the specified section, if there is one.
function easyliquids.deleteLiquid(section)

	if liquidTables[section] then

		if liquidTables[section].light then
			Darkness.removeLight(liquidTables[section].light)
		end

		liquidTables[section] = nil

		if liquidObjs[section] then
			if type(liquidObjs[section]) == "BoxCollider" then
				liquidObjs[section] = nil
			else
				liquidObjs[section].isHidden = true
			end
		end
	end
end


-- Moves the liquid in the specified section until it reaches its newHeight value. If other movements are currently queued, waits until they’re all done.
-- seconds determines how many seconds it will take.
-- easing determines the easing function used.
-- waittime determines how many seconds the liquid will wait before starting the next queued movement.
function easyliquids.moveLiquid(section, newHeight, seconds, easing, waittime)
	movement_error_handling(section, newHeight, seconds, easing, waittime)

	local wait = waittime or 0
	setLiquidPosition(liquidTables[section], newHeight, seconds * 60 or 0, easing or easyliquids.EASING_LINEAR, wait * 60)
end

-- Same as easyliquids.moveLiquid(), but uses block measurements.
function easyliquids.moveLiquidBlocks(section, newHeight, seconds, easing, waittime)
	movement_error_handling(section, newHeight, seconds, easing, waittime)
	
	local wait = waittime or 0
	setLiquidPosition(liquidTables[section], newHeight * 32, seconds * 60 or 0, easing or easyliquids.EASING_LINEAR, wait * 60)
end

-- Instantly moves the liquid in the specified section until it reaches the specified y position. This method uses scene-space coordinates.
function easyliquids.setLiquidY(section, y)
	local sct = Section(section)
	setLiquidPosition(liquidTables[section], sct.boundary.bottom - y, 0, easyliquids.EASING_LINEAR, 0)
end

-- Adds a custom style to the library’s styles table and returns its index.
function easyliquids.createStyle(args)

	style_error_handling(args)

	newstyle = {}

	styletype = args.liquidtype or easyliquids.TYPE_WATER

	if styletype == easyliquids.TYPE_WATER then
		newstyle.bgoID = args.bgoID
		table.insert(liquidTextures[easyliquids.TYPE_WATER], Graphics.loadImageResolved("background-" .. tostring(args.bgoID) .. ".png"))
	elseif styletype == easyliquids.TYPE_LAVA then
		newstyle.blockID = args.blockID
		newstyle.glowcolor = args.glowcolor or Color.red
		table.insert(liquidTextures[easyliquids.TYPE_LAVA], Graphics.loadImageResolved("block-" .. tostring(args.blockID) .. ".png"))
	end

	newstyle.frames = args.frames or 4
	newstyle.framespeed = args.framespeed or 8
	newstyle.priority = args.priority or -10
	newstyle.opacity = args.opacity or 0.6

	table.insert(liquidStyles[styletype], newstyle)
	return #liquidStyles[styletype]

end

-- Returns the height of the liquid in the specified section or nil if there isn’t one.
function easyliquids.getLiquidHeight(section)

	if not is_integer(section) then
		return nil
	end

	if section < 0 or section > 20 then
		return nil
	end
	
	if liquidTables[section] then
		return liquidTables[section].height
	else
		return nil
	end
end

-- Returns the y position in scene-space coordinates of the liquid in the specified section or nil if there isn’t one.
function easyliquids.getLiquidY(section)

	if not is_integer(section) then
		return nil
	end

	if section < 0 or section > 20 then
		return nil
	end

	bound = Section(section).boundary.bottom
	
	if liquidTables[section] then
		return bound - liquidTables[section].height
	else
		return nil
	end
end

-- Spawns a liquid with the specified arguments.
-- Takes the same arguments used to initialize the levelLiquids table, plus an additional section argument to specify the section where the liquid will be spawned.
function easyliquids.createLiquid(section, args)

	liquid_error_handling(section, args)
	
	if liquidTables[section] then
		easyliquids.deleteLiquid(section)
	end
	
	local sct = Section(section)
	local bounds = sct.boundary
	
	newLiquid = {}
	newLiquid.height = args.height or args.blockheight * 32
	newLiquid.originheight = newLiquid.height
	newLiquid.liquidtype = args.liquidtype or easyliquids.TYPE_WATER
	newLiquid.style = args.style or easyliquids.STYLE_SMM2
	newLiquid.goback = args.goback or false

	newLiquid.moving = false
	newLiquid.moveTimer = -1
	newLiquid.moveBackTimer = -1
	newLiquid.static = not (args.targetheight or args.targetblockheight or args.movetime)
	newLiquid.section = section

	newLiquid.signals = {}
	newLiquid.movements = 0
	
	if args.targetheight then
		newLiquid.targetheight = args.targetheight
	elseif args.targetblockheight then
		newLiquid.targetheight = args.targetblockheight * 32
	else
		newLiquid.targetheight = math.abs(bounds.top - bounds.bottom) + 32
	end

	if args.waittime then
		newLiquid.waittime = args.waittime * 60
	else
		newLiquid.waittime = 0
	end

	newLiquid.easing = args.easing or easyliquids.EASING_LINEAR
	newLiquid.bounds = bounds

	if args.movetime then
		newLiquid.movetime = args.movetime * 60
	else
		newLiquid.movetime = math.abs(newLiquid.targetheight - newLiquid.originheight) * 1.5
	end

	if newLiquid.liquidtype == easyliquids.TYPE_LAVA then
		newLiquid.light = Darkness.light{
			type = Darkness.lighttype.BOX,
			x = bounds.left + (bounds.right - bounds.left) * 0.5,
			y = (bounds.bottom - newLiquid.height) + newLiquid.height * 0.5,
			width = bounds.right - bounds.left,
			height = newLiquid.height,
			radius = 32,
			color = liquidStyles[easyliquids.TYPE_LAVA][newLiquid.style].glowcolor
		}

		Darkness.addLight(newLiquid.light)
	else
		newLiquid.light = nil
	end

	liquidTables[section] = newLiquid

	if newLiquid.liquidtype == easyliquids.TYPE_WATER then
		if liquidObjs[section] then
			liquidObjs[section].isHidden = false
		else
			liquidObjs[section] = spawnLiquid(bounds.left, bounds.bottom - newLiquid.height + 16, bounds.right - bounds.left, newLiquid.height - 16, false)
		end
	elseif newLiquid.liquidtype == easyliquids.TYPE_LAVA then
		liquidObjs[section] = Colliders.Box(bounds.left, bounds.bottom - newLiquid.height, bounds.right - bounds.left, newLiquid.height)
	end

	setLiquidPosition(newLiquid, newLiquid.height, 0, transition.EASING_LINEAR, 0)
end

function easyliquids.initLiquids()

	for k, v in pairs(liquidObjs) do
		transition.clear(v)
	end

	for k, v in pairs(liquidTables) do
		transition.clear(v)
		easyliquids.deleteLiquid(k)
	end

	for k, v in pairs(easyliquids.levelLiquids) do
		easyliquids.createLiquid(k, v)
	end

end

function easyliquids.onInitAPI()
	registerEvent(easyliquids, "onStart")
	registerEvent(easyliquids, "onTick")
	registerEvent(easyliquids, "onDraw")

	liquidTextures[easyliquids.TYPE_WATER] = {} 
	for k,v in pairs(liquidStyles[easyliquids.TYPE_WATER]) do
		if Misc.resolveGraphicsFile("background-" .. tostring(v.bgoID) .. ".png") then
			liquidTextures[easyliquids.TYPE_WATER][k] = Graphics.loadImageResolved("background-" .. tostring(v.bgoID) .. ".png")
		else
			liquidTextures[easyliquids.TYPE_WATER][k] = nil
		end
	end

	liquidTextures[easyliquids.TYPE_LAVA] = {} 
	for k,v in pairs(liquidStyles[easyliquids.TYPE_LAVA]) do
		if Misc.resolveGraphicsFile("block-" .. tostring(v.blockID) .. ".png") then
			liquidTextures[easyliquids.TYPE_LAVA][k] = Graphics.loadImageResolved("block-" .. tostring(v.blockID) .. ".png")
		else
			liquidTextures[easyliquids.TYPE_LAVA][k] = nil
		end
	end
end

function easyliquids.onStart()
	easyliquids.initLiquids()
end

function easyliquids.onTick()
	
	for k, liquid in pairs(liquidTables) do

		if not liquid.static then

			if liquid.moveTimer == -1 and liquid.moveBackTimer == -1 then
				liquid.moveTimer = liquid.waittime
		
				if liquid.goback then
					liquid.moveBackTimer = liquid.movetime + liquid.waittime * 2
				end
			end
		
			if liquid.moveTimer > 0 then
				liquid.moveTimer = liquid.moveTimer - 1
			end
		
			if liquid.goback and liquid.moveBackTimer > 0 then
				liquid.moveBackTimer = liquid.moveBackTimer - 1
			end

			if liquid.moveTimer == 0 then
				liquid.moving = true
				setLiquidPosition(liquid, liquid.targetheight, liquid.movetime, liquid.easing, 0)
				Routine.signal(liquid.section)

				liquid.moveTimer = liquid.movetime * 2 + liquid.waittime * 2
			end

			if liquid.goback and liquid.moveBackTimer == 0 then
				setLiquidPosition(liquid, liquid.originheight, liquid.movetime, liquid.easing, 0)

				liquid.moveBackTimer = liquid.movetime * 2 + liquid.waittime * 2
			end

			liquid.height = math.floor(liquid.height)

		end
	end

	if liquidTables[player.section] and type(liquidObjs[player.section]) == "BoxCollider" then

		local box = liquidObjs[player.section]
		local h = player.sectionObj.boundary.bottom - liquidTables[player.section].height

		if player.deathTimer == 0 and Colliders.collide(player, box) then
			if player.mount == MOUNT_BOOT and player.mountColor == BOOTCOLOR_RED then
				player.speedY = 0
				player.y = h - player.height

				Effect.spawn(74, player.x + 16 + RNG.randomInt(-24, 8), player.y + player.height - 4)
			else
				player:kill(HARM_TYPE_LAVA)
			end
		end

		local collision = Colliders.getColliding({a = box, b = NPC.HITTABLE .. NPC.UNHITTABLE, btype = Colliders.NPC})

		for k,v in pairs(collision) do
			if not (table.contains(IMMUNE_NPCS, v.id) or table.contains(SOLID_ON_LAVA, v.id)) then
				v:harm(HARM_TYPE_LAVA)
			end
		end 

		for k,v in pairs(NPC.get(SOLID_ON_LAVA)) do

			if v.y > h - v.height then
				if v.id == 297 then
					v.data._basegame.velocity.y = -v.data._basegame.velocity.y
				else
					v.speedY = 0
					v.collidesBlockBottom = true
					v.y = h - v.height
				end
			end

		end

		for k,v in pairs(NPC.get(589)) do

			if v.data._basegame.state == 2 then
				v.speedY = 0
				v.collidesBlockBottom = true

				if v.y > h then
					v.y = h + 64
				end
			elseif v.y > h + 32 and v.speedY > 0 then
				v.data._basegame.state = 2
				Effect.spawn(13, v.x + 16, h - 32)
				SFX.play(16)
			end 
		end

		for k,v in ipairs(NPC.get(195)) do

			local riding = player:mem(0x44, FIELD_BOOL) and v.y - player.y - player.height == 0

			if v.y > h - 34 then
				v.collidesBlockBottom = true
				v.y = h - v.height
				v.speedY = 0

				if riding and player.keys.jump == 1 then
					v.speedY = -6
					SFX.play(33)
				end
			elseif riding and v.speedY < 0 then
				if player.keys.jump then
					v.speedY = v.speedY - 0.1
				else
					v.speedY = v.speedY + 0.1
				end
			end
		end

	end
end

function easyliquids.onDraw()

	if liquidTables[player.section] then

		local liquid = liquidTables[player.section]

		frame = math.floor(lunatime.drawtick() / liquidStyles[liquid.liquidtype][liquid.style].framespeed) % liquidStyles[liquid.liquidtype][liquid.style].frames
		drawLiquid(liquid)
	end

end

return easyliquids