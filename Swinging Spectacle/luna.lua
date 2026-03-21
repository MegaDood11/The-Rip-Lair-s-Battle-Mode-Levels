local battlePlayer = require("scripts/battlePlayer")

function onTick()
    for _,p in ipairs(battlePlayer.getActivePlayers()) do
        local bdata = battlePlayer.getPlayerData(p)
        --Misc.dialog(bdata)
        if p.isValid and p.deathTimer == 0 and bdata.respawnTimer == 0 then
            if not p.data.spotLight then
                p.data.spotLight = Darkness.light{x = p.x + p.width * 0.5, y = p.y + p.height * 0.5, radius = 64,brightness = 1}
                Darkness.addLight(p.data.spotLight)
                p.data.spotLight:attach(p,true)
            end
            p.data.spotLight.brightness = 1
        else
            if p.data.spotLight then
                p.data.spotLight.brightness = 0
            end
        end
    end
    for _,p in ipairs(Player.get()) do
        if not battlePlayer.getPlayerIsActive(p) and p.data.spotLight then
            p.data.spotLight:destroy()
            p.data.spotLight = nil
        end
    end
end
