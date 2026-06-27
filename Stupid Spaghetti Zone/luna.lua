function onDraw()
	for _,v in ipairs(BGO.get()) do
		if v.id >= 203 and v.id <= 218 then
			BGO.config[v.id].priority = -1000
		end
	end
end