local verletrope = require("verletrope")

local function makeSegment(pos)
	local t = {position = pos, oldpos = pos, fixed = false}
	return t
end

local function makeCloth(topLeft, topRight, bottomLeft, bottomRight, divisionsX, divisionsY, iterations, gravity, allowCompress)
	local c = verletrope.Cloth(topLeft, topRight, bottomLeft, bottomRight, 2, iterations, gravity, allowCompress)
	
	c.strands = {}
	
	for i = 1,divisionsX do
		local startPos = math.lerp(topLeft,topRight,(i-1)/(divisionsX-1))
		local endPos = math.lerp(bottomLeft,bottomRight,(i-1)/(divisionsX-1))
		local v = startPos
		local d = (endPos-startPos)/divisionsY
		
		local r = {startPos = startPos, endPos = endPos, segmentLength = d.length, segments = {}}
		
		for i=1,divisionsY do
			table.insert(r.segments, makeSegment(v))
			v = v + d
		end
		
		r.segments[1].fixed = true
		
		table.insert(c.strands, r)
	end
	
	return c
end

verletrope.Cloth2 = makeCloth

return verletrope