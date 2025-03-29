if engine.ActiveGamemode() != "sandbox" then return end

if SERVER then
	util.AddNetworkString("GP_LoadReplay")
	util.AddNetworkString("GP_SendReplays")

	local playerData
	local roundData
	local IDToAuthor, AuthorToID
	local function LoadReplay(ply, lefile)
		if isnumber(lefile) then
			lefile = file.Find("garryphone/" .. game.GetMap() .. "/*", "DATA")[lefile]:gsub(".txt", "")
		end

		local f = file.Read("garryphone/" .. game.GetMap() .. "/" .. lefile .. ".txt", "DATA")
		if !f then return end

		f = f:Split("\n")

		playerData = util.JSONToTable(f[1], false, true)
		roundData = util.JSONToTable(f[2], false, true)
		IDToAuthor, AuthorToID = {}, {}

		local plyCount = 0
		local toSend = {}
		for sid, data in pairs(roundData) do
			plyCount = plyCount + 1

			local authorID = data[1].author

			IDToAuthor[plyCount] = authorID
			AuthorToID[authorID] = plyCount

			toSend[plyCount] = {author = playerData[authorID]}

			for i = 1, #data do
				local tbl = data[i]
				local tblData = tbl.data
				local isPrompt = isstring(tblData)

				toSend[plyCount][i] = {author = tbl.author, prompt = isPrompt}
				if isPrompt then
					toSend[plyCount][i].data = tblData
				end
			end
		end

		net.Start("GP_LoadReplay")
			net.WriteUInt(plyCount, 7)
			for i = 1, plyCount do
				local data = toSend[i]
				net.WriteString(data.author)

				for j = 1, #data do
					local round = data[j]
					local isPrompt = round.prompt

					net.WriteUInt(AuthorToID[round.author], 7)
					net.WriteBool(isPrompt)
					if isPrompt then
						net.WriteString(round.data)
					end
				end
			end
		net.Send(ply)
	end
	net.Receive("GP_SendReplays", function(_, ply)
		if !ply:IsListenServerHost() then return end

		LoadReplay(ply, net.ReadUInt(8))
	end)

	concommand.Add("gp_loadreplay", function(ply, cmd, args)
		if !ply:IsListenServerHost() or !file.Exists("garryphone", "DATA") then
			print("No replays found!")

			return
		end

		local lefile = args[1]
		if !lefile then
			local files = file.Find("garryphone/" .. game.GetMap() .. "/*", "DATA")
			if #files == 0 then
				print("No replays found on this map!")

				return
			end

			net.Start("GP_SendReplays")
				net.WriteUInt(#files, 8)
				for i = 1, #files do
					local f = files[i]:gsub(".txt", "")
					net.WriteString(f)
				end
			net.Send(ply)

			return
		end

		LoadReplay(ply, lefile)
	end, function(cmd)
		local files = file.Find("garryphone/" .. game.GetMap() .. "/*", "DATA")
		for i = 1, #files do
			local f = files[i]
			f = f:gsub(".txt", "")

			files[i] = cmd .. [[ "]] .. f .. [["]]
		end

		return files
	end)

	net.Receive("GP_LoadReplay", function(_, ply)
		if !ply:IsListenServerHost() then return end

		game.CleanUpMap()

		local i, j = net.ReadUInt(7), net.ReadUInt(7)
		local author = IDToAuthor[i]

		local data = roundData[author][j].data
		duplicator.Paste(ply, data.Entities, data.Constraints)

		if data.pos and data.ang then
			for _, p in player.Iterator() do
				p:SetPos(data.pos)
				p:SetEyeAngles(data.ang)
			end
		end
	end)
else
	local function ReplayMenu(data)
		local w, h = 800, 600

		local frame = vgui.Create("DFrame")
		frame:SetSize(w, h)
		frame:Center()
		frame:SetTitle("Garry Phone Replay")
		frame:MakePopup()

		local replay = vgui.Create("DPanelList", frame)
		replay:SetPos(15, 15 * 2)
		replay:SetSize(w - 15 * 2, h - 15 * 3)
		replay:EnableVerticalScrollbar()

		for i = 1, #data do
			local round = data[i]

			local dgui = vgui.Create("DForm", replay)
			dgui:SetName(data[round[1].author].author)

			for j = 1, #round do
				local tbl = round[j]
				local str = data[tbl.author].author .. ": "

				if tbl.prompt then
					str = str .. tbl.data
				else
					str = str .. "(BUILD)"
				end

				local btn = dgui:Button(str)
				if tbl.prompt then
					btn:SetEnabled(false)
				else
					btn.DoClick = function()
						net.Start("GP_LoadReplay")
							net.WriteUInt(i, 7)
							net.WriteUInt(j, 7)
						net.SendToServer()
					end
				end
			end

			replay:AddItem(dgui)
		end
	end

	net.Receive("GP_LoadReplay", function()
		local plyCount = net.ReadUInt(7)
		local data = {}
		for i = 1, plyCount do
			data[i] = {author = net.ReadString()}

			for j = 1, plyCount do
				data[i][j] = {author = net.ReadUInt(7), prompt = net.ReadBool()}
				if data[i][j].prompt then
					data[i][j].data = net.ReadString()
				end
			end
		end

		ReplayMenu(data)
	end)

	net.Receive("GP_SendReplays", function()
		local w = ScrW()
		local h = ScrH()

		local dframe = vgui.Create("DFrame")
		dframe:SetSize(w / 8, h / 4)
		dframe:SetPos((w / 2) - ((w / 8) / 2), (h / 2) - ((h / 4) / 2))
		dframe:SetTitle("Replay Select")
		dframe:MakePopup()

		local dlist = vgui.Create("DScrollPanel", dframe)
		dlist:Dock(FILL)

		local num = net.ReadUInt(8)

		for i = 1, num do
			local name = net.ReadString()

			local dbutton = dlist:Add("DButton")

			dbutton:SetText(name)
			dbutton:Dock(TOP)
			dbutton:DockMargin(0, 0, 0, 5)

			function dbutton:DoClick()
				net.Start("GP_SendReplays")
					net.WriteUInt(i, 8)
				net.SendToServer()

				dframe:Close()
			end
		end
	end)
end