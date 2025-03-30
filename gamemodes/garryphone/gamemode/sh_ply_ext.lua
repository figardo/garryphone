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

if SERVER then
	function meta:SetBuildSpawn(pos, ang)
		if !self.BuildSpawn then self.BuildSpawn = {} end

		self.BuildSpawn.pos = pos or self:GetPos()
		self.BuildSpawn.ang = ang or self:GetAngles()

		net.Start("GP_SetSpawn")
			net.WriteVector(self.BuildSpawn.pos)
			net.WriteFloat(self.BuildSpawn.ang.y)
		net.Send(self)
	end
end