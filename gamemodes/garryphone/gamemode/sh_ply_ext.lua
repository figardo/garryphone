local meta = FindMetaTable("Player")

function meta:HasAuthority()
    if !game.IsDedicated() then
        return self:IsListenServerHost()
    end

    local adminsPresent = false
    for _, ply in player.Iterator() do
        if !ply:IsAdmin() then continue end

        adminsPresent = true
        break
    end

    return adminsPresent and self:IsAdmin() or self:EntIndex() == 1
end