DEFINE_BASECLASS("gamemode_sandbox")

function GM:SaveBuilds(round, asdupe)
	for id, data in pairs(undo.GetTable()) do
		local ply = player.GetByUniqueID(id)
		if !IsValid(ply) or !data[1] then continue end

		ply:SaveBuild(data, asdupe, round)
	end
end

function GM:BuildsToDupes(round)
	-- convert build data into a format that can be respawned
	for _, tbl in pairs(self.RoundData) do
		local build = tbl[round - 1].data
		if !build or !istable(build) then continue end

		local newBuild = table.Copy(build)
		newBuild.pos = nil
		newBuild.ang = nil

		tbl[round - 1].data = duplicator.CopyEnts(newBuild)
		tbl[round - 1].data.pos = build.pos
		tbl[round - 1].data.ang = build.ang
	end
end

local ready = {}
function SetReady(sid, bool)
	ready[sid] = bool
end

function GetReady(sid)
	return ready[sid]
end

function GM:ShowSpare1(ply)
	if GetRoundState() != STATE_BUILD then return end

	ply:SetBuildSpawn()
end

function GM:ShowSpare2(ply)
	if GetRoundState() != STATE_BUILD then return end

	local old = ply:GetReady()
	ply:SetReady(!old)

	if !old then
		ply:SetBuildSpawn()
	end

	net.Start("GP_Ready")
		net.WriteBool(!old)
	net.Send(ply)
end


function GM:OnEntityCreated(ent)
	if ent:CreatedByMap() then return end

	local rs = GetRoundState()
	if rs == STATE_LOBBY or rs == STATE_POST then return end

	-- ent:SetTransmitWithParent(true)

	timer.Simple(0, function()
		if !IsValid(ent) or ent.GP_Hidden or ent:EntIndex() == 0 then return end

		local ply = ent:GetCreator()
		if IsValid(ply) then
			return self:PreventTransmitAll(ent, ply, true)
		end

		ply = ent.GetPlayer and ent:GetPlayer()
		if IsValid(ply) then
			return self:PreventTransmitAll(ent, ply, true)
		end

		ply = ent:GetOwner()
		if IsValid(ply) then
			return self:PreventTransmitAll(ent, ply, true)
		end

		ply = ent:GetParent()
		while IsValid(ply) do
			if ply.GP_Hidden then
				local owner = ply:GetNWEntity("GP_Owner")
				return self:PreventTransmitAll(ent, owner, true)
			end

			if !ply:IsPlayer() then
				ply = ply:GetParent()
				continue
			end

			return self:PreventTransmitAll(ent, ply, true)
		end
	end)
end

function GM:CanCreateUndo(ply, tbl)
	local rs = GetRoundState()
	if rs == STATE_LOBBY or rs == STATE_POST then return end

	local ent = tbl.Entities
	for i = 1, #ent do
		local e = ent[i]
		if e.GP_Hidden then continue end

		self:PreventTransmitAll(e, ply, true)
	end
end

function GM:SpawnBuildEnt(ply, ent)
	ent:SetCustomCollisionCheck(true)
	ent:CollisionRulesChanged()

	if GetRoundState() != STATE_BUILD then return end

	ent:SetNWEntity("GP_Owner", ply)

	local plys = self.Playing
	for i = 1, #plys do
		local pl = self.PlayerData[plys[i]].ply
		if !IsValid(pl) or pl == ply then continue end

		RecursiveSetPreventTransmit(ent, pl, true)
	end
end

function GM:PlayerSpawnedEffect(ply, mdl, ent)
	BaseClass.PlayerSpawnedEffect(self, ply, mdl, ent)

	self:SpawnBuildEnt(ply, ent)
end

function GM:PlayerSpawnedNPC(ply, ent)
	BaseClass.PlayerSpawnedNPC(self, ply, ent)

	self:SpawnBuildEnt(ply, ent)
end

function GM:PlayerSpawnedProp(ply, mdl, ent)
	BaseClass.PlayerSpawnedProp(self, ply, mdl, ent)

	self:SpawnBuildEnt(ply, ent)
end

function GM:PlayerSpawnedRagdoll(ply, mdl, ent)
	BaseClass.PlayerSpawnedRagdoll(self, ply, mdl, ent)

	self:SpawnBuildEnt(ply, ent)
end

function GM:PlayerSpawnedSENT(ply, ent)
	BaseClass.PlayerSpawnedSENT(self, ply, ent)

	self:SpawnBuildEnt(ply, ent)
end

function GM:PlayerSpawnedSWEP(ply, ent)
	BaseClass.PlayerSpawnedSWEP(self, ply, ent)

	self:SpawnBuildEnt(ply, ent)
end

function GM:PlayerSpawnedVehicle(ply, ent)
	BaseClass.PlayerSpawnedVehicle(self, ply, ent)

	self:SpawnBuildEnt(ply, ent)
end

local buildStates = {
	[STATE_LOBBY] = true,
	[STATE_BUILD] = true,
	[STATE_POST] = true
}

function GM:PlayerSpawnEffect(ply)
	return buildStates[GetRoundState()]
end

local gp_allownpcs = CreateConVar("gp_allownpcs", "1", FCVAR_ARCHIVE, "Allow spawning NPCs.", 0, 1)
function GM:PlayerSpawnNPC(ply)
	return gp_allownpcs:GetBool() and buildStates[GetRoundState()]
end

function GM:PlayerSpawnObject(ply)
	return buildStates[GetRoundState()]
end

function GM:PlayerSpawnProp(ply)
	return buildStates[GetRoundState()]
end

function GM:PlayerSpawnRagdoll(ply)
	return buildStates[GetRoundState()]
end

local gp_allowsents = CreateConVar("gp_allowsents", "0", FCVAR_ARCHIVE, "Allow spawning SENTs. This can potentially break things!", 0, 1)
function GM:PlayerSpawnSENT(ply)
	return gp_allowsents:GetBool() and buildStates[GetRoundState()]
end

function GM:PlayerSpawnSWEP(ply)
	return buildStates[GetRoundState()]
end

function GM:PlayerSpawnVehicle(ply)
	return buildStates[GetRoundState()]
end

function GM:CanTool(ply)
	return buildStates[GetRoundState()]
end

function GM:CanDrive(ply)
	return buildStates[GetRoundState()]
end

function GM:PlayerGiveSWEP(ply, wep, tbl)
	Spawn_Weapon(ply, wep)

	return false
end

function GM:CanUndo(ply, tbl)
	return !IsValid(tbl.Entities[1]) or !tbl.Lock
end