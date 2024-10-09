local sz = {}

function sz.onInitAPI()
    registerEvent(sz, "onStart")
    registerEvent(sz, "onTick")
end

sz.block = 27

function sz.onTick()
    for k,v in ipairs(Block.getIntersecting(player.x, player.y, player.x + player.width, player.y + player.height)) do
        if v.id == sz.block then
            for k,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
                if not n.isHidden then
                    if n:mem(0x124,FIELD_BOOL) then
                        n:mem(0x12A, FIELD_WORD, 180)
                    elseif n:mem(0x12A, FIELD_WORD) == -1 then
                        if n.x + n.width < camera.x or n.x > camera.x + camera.width or n.y > camera.y + camera.height or n.y + n.height < camera.y then
                            n:mem(0x124,FIELD_BOOL, true)
                            n:mem(0x12A, FIELD_WORD, 180)
                        end
                    end
                    n:mem(0x74, FIELD_BOOL, true)
                end
            end
        end
    end
end

function sz.onStart()
    for k,v in ipairs(Block.get(sz.block)) do
        v.isHidden = true
    end
end

return sz