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

	function meta:SetReady(bool)
		SetReady(self:SteamID64(), bool)
	end

	function meta:GetReady()
		return GetReady(self:SteamID64())
	end

	function meta:SaveBuild(data, asdupe, round)
		data = data or undo.GetTable()[self:UniqueID()]
		if !data then return end

		round = round or GetRound()

		local build = {}
		for i = 1, #data do
			data[i].Lock = true

			local props = data[i].Entities
			if !props then continue end
			for j = 1, #props do
				local prop = props[j]
				-- HACK: there's probably a better way to ignore ents created for a constraint
				if !IsValid(prop) or prop:IsConstraint() or prop:GetClass() == "gmod_winch_controller" then continue end

				build[#build + 1] = prop
			end
		end

		if asdupe then
			build = duplicator.CopyEnts(build)
		end

		if self.BuildSpawn and !table.IsEmpty(self.BuildSpawn) then
			build.pos = self.BuildSpawn.pos
			build.ang = self.BuildSpawn.ang

			self.BuildSpawn = nil
		else
			build.pos = self:GetPos()
			build.ang = self:EyeAngles()
		end

		local recipient = GAMEMODE:GetRecipient(self)

		GAMEMODE.RoundData[recipient][round].data = build
	end
end