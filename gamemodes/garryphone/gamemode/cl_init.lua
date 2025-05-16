include("shared.lua")
include("sh_ply_ext.lua")
include("cl_hud.lua")
include("cl_menus.lua")
include("cl_postgame.lua")

local vguiLua = file.Find("garryphone/gamemode/vgui/*", "LUA")
for i = 1, #vguiLua do
	include("vgui/" .. vguiLua[i])
end

function GM:Initialize()
	self.LobbyOpen = false
end

function GM:InitPostEntity()
	self:CreateConVars()
end

local function GenerateFonts()
	surface.CreateFont("GPTargetID", {
		font = "Comic Sans MS",
		size = ScreenScaleH(15),
		outline = true,
		extended = true
	})

	surface.CreateFont("GPTextEntry", {
		font = "Comic Sans MS",
		size = ScreenScaleH(15),
		extended = true
	})

	surface.CreateFont("GPBoldSmall", {
		font = "Comic Sans MS",
		size = ScreenScaleH(15),
		weight = 900,
		extended = true
	})

	surface.CreateFont("GPTitle", {
		font = "Comic Sans MS",
		size = ScreenScaleH(20),
		outline = true,
		extended = true
	})

	surface.CreateFont("GPBold", {
		font = "Comic Sans MS",
		size = ScreenScaleH(25),
		weight = 900,
		extended = true
	})
end
GenerateFonts()

function GM:OnScreenSizeChanged()
	GenerateFonts()
end

local online = Sound("friends/friend_online.wav")
local join = Sound("friends/friend_join.wav")
local message = Sound("friends/message.wav")

local stateSwitchFuncs = {
	[STATE_LOBBY] = function(gm)
		gm.GameOver = false
		gm.RoundSaved = false
	end,
	[STATE_PROMPT] = function(gm)
		gm:OnSpawnMenuClose()

		gm.MenuLock = true
		gm:KillMenuScreen(true)

		gm:CreatePromptScreen()

		return online
	end,
	[STATE_BUILD] = function(gm)
		gm:ScoreboardHide()

		gm.MenuLock = true
		gm.MenuOpen = false
		gm:KillMenuScreen(GetRound() != 1)

		gm:CreateBuildText()

		return online
	end,
	[STATE_POST] = function(gm)
		gm.MenuLock = false
		gm.MenuOpen = false
		gm:KillMenuScreen(true)

		gm.PostText = language.GetPhrase("GarryPhone.GameOver")
		if LocalPlayer():HasAuthority() then
			local tab = input.LookupBinding("+showscores") or "NOT BOUND"
			gm.PostText = gm.PostText .. " " .. language.GetPhrase("GarryPhone.ViewResults"):format(tab)
		end

		gm.RoundData = {}

		gm.CurPly = nil
		gm.CurRound = nil
		gm.HighlightedPly = 1
		gm.AlbumText = language.GetPhrase("GarryPhone.Album"):format(Entity(1):Nick())
		gm.NextPly = false

		return join
	end
}

local infiniteTime
local rs, lastAlert
function GM:Think()
	local newrs = GetRoundState()

	if !infiniteTime then
		infiniteTime = GetConVar("gp_infinitetime")
	end

	if (newrs == STATE_PROMPT or newrs == STATE_BUILD) and !infiniteTime:GetBool() then
		local time = math.ceil(math.max(0, GetRoundTime() - CurTime()))
		if time <= 5 and time != 0 then
			if time < lastAlert then
				surface.PlaySound(message)
				lastAlert = time
			end
		else
			lastAlert = 6
		end
	end

	if rs == newrs then return end

	rs = newrs

	self.Ready = false

	if IsValid(self.ReadyMark) then
		self.ReadyMark:Remove()
	end

	local fn = stateSwitchFuncs[rs]
	if !fn then return end

	local snd = fn(self)
	if !snd then return end

	surface.PlaySound(snd)
end

local function ReceivePrompt()
	local prompt = net.ReadString()
	prompt = prompt or ""

	local pnl = GAMEMODE.TextPanel
	if IsValid(pnl) and pnl:GetClassName() == "DTextEntry" then
		pnl:SetPlaceholderText(prompt)
	end

	GAMEMODE.CurPrompt = prompt
end
net.Receive("GP_SendPrompt", ReceivePrompt)

local function ShowResults()
	if GetRoundState() != STATE_POST then return end

	local gm = GAMEMODE
	gm.MenuOpen = net.ReadBool()

	if gm.MenuOpen then
		gm:CreateMenu()
		gm:CreatePostScreen()
	else
		gm:KillMenuScreen()
	end
end
net.Receive("GP_ShowResults", ShowResults)

function GM:SetMark(pos, y)
	local mark = self.ReadyMark

	if IsValid(mark) then
		mark:Remove()
	end

	mark = ClientsideModel("models/editor/playerstart.mdl")
	mark:SetPos(pos)
	mark:SetAngles(Angle(0, y, 0))
	mark:Spawn()

	self.ReadyMark = mark
end
net.Receive("GP_SetSpawn", function() GAMEMODE:SetMark(net.ReadVector(), net.ReadFloat()) end)

local function Ready()
	GAMEMODE.Ready = net.ReadBool()
end
net.Receive("GP_Ready", Ready)