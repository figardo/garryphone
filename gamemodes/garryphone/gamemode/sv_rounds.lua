local game_mode = CreateConVar("gp_gamemode", "default")

-- playin sudoku
local function DoPlayerOrder(plyCount, plyOrder, row, col)
	if row == plyCount + 1 then
		return true
	end

	if col == plyCount then
		return DoPlayerOrder(plyCount, plyOrder, row + 1, 1)
	end

	for num = 1, plyCount do
		if num == row then continue end

		local valid = true
		for i = 1, plyCount do
			if plyOrder[row][i] == num or plyOrder[i][col] == num then
				valid = false
				break
			end
		end

		if !valid then continue end

		plyOrder[row][col] = num

		if DoPlayerOrder(plyCount, plyOrder, row, col + 1) then
			return true
		end

		plyOrder[row][col] = nil
	end

	return false
end

function GM:StartGame()
	game.CleanUpMap()

	self.BuildRoundPlayed = false

	self.PlayerData = {}
	self.Playing = {}

	self.RoundData = {}
	self.BuildRounds = {}

	local plys = select(2, player.Iterator())
	for i = 1, #plys do
		local ply = plys[i]
		if ply:Team() == TEAM_SPECTATOR then continue end

		local sid = ply:SteamID64()

		self.PlayerData[sid] = {ply = ply, name = ply:Nick()}
		table.insert(self.Playing, sid)

		ply:SetTeam(TEAM_PLAYING)
	end

	local plyCount = #self.Playing

	local plyOrder = {}
	for i = 1, plyCount do
		plyOrder[i] = {}
	end

	if !DoPlayerOrder(plyCount, plyOrder, 1, 1) then
		error("Player ordering error! Something went very wrong!")
		return
	end

	local gm = game_mode:GetString()
	local orderFn = self.Gamemodes[gm] or self.Gamemodes["default"]
	orderFn = orderFn.order

	for i = 1, plyCount do
		local sid = self.Playing[i]
		self.RoundData[sid] = {{author = sid}}

		for j = 2, plyCount do
			local authorsid = self.Playing[plyOrder[i][j - 1]]
			self.RoundData[sid][j] = {author = authorsid}

			if !self.PlayerData[authorsid].order then
				self.PlayerData[authorsid].order = {}
			end

			self.PlayerData[authorsid].order[j] = sid
		end

		self.BuildRounds[i] = orderFn(i, plyCount)
	end

	for _, ply in player.Iterator() do
		ply:Spawn()
	end

	net.Start("GP_NewRound")
	net.Broadcast()

	SetRound(1)
	self:SwitchToPrompt(1)
end

function GM:IsBuildRound(round)
	return self.BuildRounds[round]
end

local promptTime
function GM:SwitchToPrompt(curRound)
	if !promptTime then
		promptTime = GetConVar("gp_prompttime")
	end

	SetRoundTime(promptTime:GetFloat())

	for sid, data in pairs(self.PlayerData) do
		SetReady(sid, false)
	end

	if curRound > 1 then
		self:SaveBuilds(curRound, false)

		for sid, data in pairs(self.PlayerData) do
			local ply = data.ply
			local validPly = IsValid(ply)
			if validPly then
				ply:Spawn()
			end

			local recipient = self:GetRecipient(sid, 1)

			local buildData = self.RoundData[recipient][curRound]
			local build = buildData.data
			if !build or #build == 0 then continue end

			local builder = self.PlayerData[buildData.author].ply

			for i = 1, #build do
				local ent = build[i]

				-- hide build from the builder
				RecursiveSetPreventTransmit(ent, builder, true)

				if validPly then
					-- show build to the guesser
					RecursiveSetPreventTransmit(ent, ply, false)
				end

				ent:SetNWEntity("GP_Owner", nil)
			end

			if validPly and build.pos and build.ang then
				ply:SetPos(build.pos)
				ply:SetEyeAngles(build.ang)
			end
		end
	end

	SetRoundState(STATE_PROMPT)
end

local buildTime
function GM:SwitchToBuild(curRound)
	if !buildTime then
		buildTime = GetConVar("gp_buildtime")
	end

	SetRoundTime(buildTime:GetFloat())

	if self.BuildRoundPlayed then
		self:BuildsToDupes(curRound)

		game.CleanUpMap()
	else
		self.BuildRoundPlayed = true
	end

	for sid, data in pairs(self.PlayerData) do
		SetReady(sid, false)

		local ply = data.ply
		if !IsValid(ply) then continue end

		ply:Spawn()
		ply:SetBuildSpawn()

		local recipient = self:GetRecipient(sid, 1)
		local str = self.RoundData[recipient][curRound].data
		if !str then str = "" end

		net.Start("GP_SendPrompt")
			net.WriteString(str)
		net.Send(ply)
	end

	SetRoundState(STATE_BUILD)
end

function GM:EndGame(curRound)
	curRound = curRound or GetRound()

	if curRound > 1 then
		local oldState = GetRoundState()
		if oldState == STATE_BUILD then
			self:SaveBuilds(curRound, true)
		else
			self:BuildsToDupes(curRound)
		end
	end

	game.CleanUpMap()

	for _, ply in player.Iterator() do
		ply:Spawn()

		for _, ply2 in player.Iterator() do
			RecursiveSetPreventTransmit(ply, ply2, false)
		end

		ply:SetTeam(TEAM_PLAYING)
	end

	self.CurPly = 1
	self.CurRound = 0

	SetRoundState(STATE_POST)

	-- PrintTable(self.RoundData)
end

local plyBits = bitsRequired(game.MaxPlayers())

local sid, data, authorID, author, authorName
function GM:LoadNextRound()
	local playing = self.Playing
	local numplaying = #playing

	self.CurRound = self.CurRound + 1

	if self.CurRound > numplaying then
		self.CurPly = self.CurPly + 1
		self.CurRound = 1
	end

	local gameOver = self.CurPly > numplaying
	local isBuild = self:IsBuildRound(self.CurRound)

	if !gameOver then
		sid = playing[self.CurPly]
		data = self.RoundData[sid][self.CurRound]

		authorID = data.author
		author = self.PlayerData[authorID].ply
		authorName = self.PlayerData[authorID].name

		data = data.data

		if isBuild then
			game.CleanUpMap()
		end
	end

	net.Start("GP_SendRound")

	net.WriteUInt(self.CurPly, plyBits)
	net.WriteUInt(self.CurRound, plyBits)

	if gameOver then
		net.WriteUInt(STATE_POST, 2) -- no rounds remaining
		net.Broadcast()

		return
	end

	net.WriteUInt(isBuild and STATE_BUILD or STATE_PROMPT, 2)

	local authorValid = IsValid(author)
	net.WriteBool(authorValid)

	if authorValid then
		net.WritePlayer(author)
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

function GM:ShowBuild()
	if !data or isstring(data) then return end

	for _, ply in player.Iterator() do
		ply:Spawn()

		if data.pos and data.ang then
			ply:SetPos(data.pos)
			ply:SetEyeAngles(data.ang)
		end
	end

	data = duplicator.Paste(self.PlayerData[authorID].ply, data.Entities, data.Constraints)

	if #data == 0 then return end

	local ent
	for i = 1, #data do
		ent = data[i]
		local valid = IsValid(ent) and ent:EntIndex()
		if valid then break end
	end

	if !IsValid(ent) then return end

	net.Start("GP_ShowBuild")
		net.WriteUInt(ent:EntIndex(), MAX_EDICT_BITS)
	net.Broadcast()
end

local function ReceivePrompt(_, ply)
	if GetRoundState() != STATE_PROMPT then return end

	local gm = GAMEMODE

	local prompt = net.ReadString()
	local recipient = ply:SteamID64()

	local curRound = GetRound()
	if curRound > 1 then
		recipient = gm:GetRecipient(recipient)
	end

	gm.RoundData[recipient][curRound].data = prompt

	if !ply:GetReady() then
		ply:SetReady(true)
	end
end
net.Receive("GP_SendPrompt", ReceivePrompt)

local infiniteTime
function GM:DoRoundTime()
	if !infiniteTime then
		infiniteTime = GetConVar("gp_infinitetime")
	end

	if infiniteTime:GetBool() or GetRoundTime() > CurTime() then return end

	self:NextRound()
end

function GM:NextRound()
	local curRound = GetRound()
	if curRound >= #self.Playing then
		self:EndGame(curRound)
	elseif self:IsBuildRound(curRound + 1) then
		self:SwitchToBuild(curRound)
	else
		self:SwitchToPrompt(curRound)
	end

	SetRound(curRound + 1)
end

local thinkStates = {
	[STATE_PROMPT] = true,
	[STATE_BUILD] = true
}

function GM:Think()
	local shouldThink = thinkStates[GetRoundState()]
	if !shouldThink then return end

	self:DoRoundTime()

	local ready = true
	for _, pdata in pairs(self.PlayerData) do
		local ply = pdata.ply
		if !IsValid(ply) then continue end

		local done = ply:GetReady()
		if !done then
			ready = done
			break
		end
	end

	if !ready then return end

	self:NextRound()
end