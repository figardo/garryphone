local plyBits = util.BitsRequired(game.MaxPlayers())

local data, authorSID, authorEnt, authorName
function GM:PostgameLoadNextRound()
	local playing = self.Playing
	local numplaying = #playing

	self.PostgameRound = self.PostgameRound + 1

	if self.PostgameRound > numplaying then
		self.PostgamePly = self.PostgamePly + 1
		self.PostgameRound = 1
	end

	local gameOver = self.PostgamePly > numplaying
	local isBuild = self:IsBuildRound(self.PostgameRound)

	if !gameOver then
		local sid = playing[self.PostgamePly]
		data = self.RoundData[sid][self.PostgameRound]

		authorSID = data.author
		authorEnt = self.PlayerData[authorSID].ply
		authorName = self.PlayerData[authorSID].name

		data = data.data

		if isBuild then
			game.CleanUpMap()
		end
	end

	net.Start("GP_SendRound")

	net.WriteUInt(self.PostgamePly, plyBits)
	net.WriteUInt(self.PostgameRound, plyBits)

	if gameOver then
		net.WriteUInt(STATE_POST, 2) -- no rounds remaining
		net.Broadcast()

		return
	end

	net.WriteUInt(isBuild and STATE_BUILD or STATE_PROMPT, 2)

	local authorValid = IsValid(authorEnt)
	net.WriteBool(authorValid)

	if authorValid then
		net.WritePlayer(authorEnt)
	else
		net.WriteString(authorName)
	end

	if !isBuild then -- prompt
		local valid = isstring(data)
		net.WriteBool(valid)

		if valid then
			net.WriteString(data)
		end
	end

	net.Broadcast()
end

function GM:PostgameShowBuild()
	if !data or isstring(data) then return end

	for _, ply in player.Iterator() do
		ply:Spawn()

		if data.pos and data.ang then
			ply:SetPos(data.pos)
			ply:SetEyeAngles(data.ang)
		end
	end

	data = duplicator.Paste(self.PlayerData[authorSID].ply, data.Entities, data.Constraints)

	if #data == 0 then return end

	local ent
	for i = 1, #data do
		ent = data[i]
		local valid = IsValid(ent) and ent:EntIndex()
		if valid then break end
	end

	if !IsValid(ent) then return end

	net.Start("GP_ShowBuild")
		net.WriteEntity(ent)
	net.Broadcast()
end

local function LoadNextRound(_, ply)
	if !ply:HasAuthority() then return end

	GAMEMODE:PostgameLoadNextRound()
end
net.Receive("GP_SendRound", LoadNextRound)

local function RevealPrompt(_, ply)
	if !ply:HasAuthority() then return end

	local gm = GAMEMODE
	if gm.PostgameRound == 1 and gm.PostgamePly != 1 then
		if !gm.NextPly then
			gm.NextPly = false
		else
			game.CleanUpMap()
		end

		gm.NextPly = !gm.NextPly
	end

	if gm:IsBuildRound(gm.PostgameRound) then
		gm:PostgameShowBuild()
	end

	net.Start("GP_RevealPrompt")
		net.WriteBool(gm.NextPly) -- did the host click "NEXT" instead of the chat button
	net.SendOmit(ply)
end
net.Receive("GP_RevealPrompt", RevealPrompt)

local function SendResults(_, ply)
	if !ply:HasAuthority() then return end

	net.Start("GP_ShowResults")
		net.WriteBool(net.ReadBool())
	net.SendOmit(ply)
end
net.Receive("GP_ShowResults", SendResults)