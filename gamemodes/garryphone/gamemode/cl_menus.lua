DEFINE_BASECLASS("gamemode_sandbox")

local grad = Material("vgui/gradient-u")
local logo = Material("vgui/gp_logo")

local roundedBG_ns = Color(57, 0, 81, 110)
local roundedBG = roundedBG_ns

local plyPnlBorder = Color(29, 0, 43)
local plyPnlCol = Color(170, 0, 255)
local plyPnlHighlight = Color(255, 0, 0)

local btnHover = Color(64, 0, 92)

local tex_corner8	= surface.GetTextureID("gui/inv_corner8")
local tex_corner16	= surface.GetTextureID("gui/inv_corner16")
local tex_corner32	= surface.GetTextureID("gui/inv_corner32")
local tex_corner64	= surface.GetTextureID("gui/inv_corner64")
local tex_corner512	= surface.GetTextureID("gui/inv_corner512")

SHADERS = GetConVar("mat_dxlevel"):GetInt() >= 90

local RNDX = SHADERS and include("vgui/rndx.lua")
if SHADERS then roundedBG = Color(57, 0, 81, 75) end

local function DrawMenu()
	local scrw, scrh = ScrW(), ScrH()

	-- background gradient
	surface.SetDrawColor(225, 0, 255)
	surface.SetMaterial(grad)
	surface.DrawTexturedRectRotated(scrw / 2, scrh / 2, scrw * 2.25, scrh * 2.25, (CurTime() * 8) % 360)

	local x, y = scrw * 0.05, scrh * 0.05
	local w, h = scrw * 0.95, scrh * 0.95

	-- border
	surface.SetDrawColor(roundedBG_ns.r, roundedBG_ns.g, roundedBG_ns.b, roundedBG_ns.a)
	surface.DrawRect(0, 0, x, scrh)
	surface.DrawRect(x, h, scrw, y)
	surface.DrawRect(x, 0, scrw, y)
	surface.DrawRect(w, y, x, scrh - (y * 2))

	-- border corners
	local cornerRad = scrh * 0.1

	if SHADERS then
		RNDX.Draw(-cornerRad, x, y, w - x, h - y, roundedBG, RNDX.SHAPE_FIGMA)
	else
		local tex
		if cornerRad > 64 then
			tex = tex_corner512
		elseif cornerRad > 32 then
			tex = tex_corner64
		elseif cornerRad > 16 then
			tex = tex_corner32
		elseif cornerRad > 8 then
			tex = tex_corner16 -- this guy is playing on an atari 2600
		else
			tex = tex_corner8 -- this guy is playing on a dreamcast vmu
		end

		surface.SetTexture(tex)
		surface.DrawTexturedRectUV(x, y, cornerRad, cornerRad, 0, 0, 1, 1) -- top left
		surface.DrawTexturedRectUV(x, h - cornerRad, cornerRad, cornerRad, 0, 1, 1, 0) -- bottom left
		surface.DrawTexturedRectUV(w - cornerRad, y, cornerRad, cornerRad, 1, 0, 0, 1) -- top right
		surface.DrawTexturedRectUV(w - cornerRad, h - cornerRad, cornerRad, cornerRad, 1, 1, 0, 0) -- bottom right
	end
end


local function DrawLobbyScreen()
	local scrw, scrh = ScrW(), ScrH()

	local x, y = scrw * 0.3, scrh * 0.085
	local w, h = scrw * 0.4, scrh * 0.12

	-- logo
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(logo)
	surface.DrawTexturedRect(x, y, w, h)
end

local prompttxt = "#GarryPhone.Write"
local function DrawPromptScreen()
	local scrw, scrh = ScrW(), ScrH()

	surface.SetTextColor(255, 255, 255, 255)
	surface.SetFont("GPTargetID")

	local tw, th = surface.GetTextSize(prompttxt)
	surface.SetTextPos((scrw / 2) - (tw / 2), (scrh * 0.45) - (th / 2))

	surface.DrawText(prompttxt)
end

function GM:CreateMenu(customdraw)
	gui.EnableScreenClicker(true)

	local pnl = vgui.Create("DPanel")
	self.MenuPanel = pnl

	local scrw, scrh = ScrW(), ScrH()
	pnl:SetSize(scrw, scrh)

	local function paint()
		DrawMenu()

		if customdraw then
			customdraw()
		end

		local children = pnl:GetChildren()
		for i = 1, #children do
			children[i]:PaintManual()
		end
	end

	pnl.Paint = function(s, w, h)
		surface.SetDrawColor(255, 255, 255, 255)

		if self.MenuBarHeight == 1 then return paint() end

		EZMASK.DrawWithMask(function()
			local y = scrh * (1 - self.MenuBarHeight)

			surface.DrawRect(0, y, scrw, scrh - y + 1)
		end, paint)
	end
end

function GM:KillMenuScreen(instant)
	gui.EnableScreenClicker(false)

	if IsValid(self.MenuPanel) then
		if instant then
			self.MenuPanel:Remove()
		else
			self.MenuPanel:AlphaTo(0, 1, 0, function(_, s) s:Remove() end)
		end
	end

	if instant and IsValid(self.TextPanel) then
		self.TextPanel:Remove()
	end
end

local plyPnlCorner = ScreenScaleH(32 / 3)
function GM:CreatePlayerPill(ply)
	local scrw, scrh = ScrW(), ScrH()

	local isReplay, name = isnumber(ply)
	if isReplay then
		local sid = self.Playing[ply]
		name = self.PlayerData[sid].name
		ply = self.PlayerData[sid].ply
	elseif IsValid(ply) then
		name = ply:Nick()
	end

	local slotPnl = vgui.Create("DPanel")
	slotPnl:SetSize(scrw * 0.2, scrh * 0.05)
	slotPnl:SetPaintedManually(true)

	local pillPaint
	if SHADERS then
		pillPaint = function(s, w, h)
			if !isReplay and !IsValid(ply) then
				RNDX.Draw(plyPnlCorner, 0, 0, w, h, plyPnlBorder, RNDX.SHAPE_CIRCLE)

				return false
			end

			local off = w * 0.01

			local col = s.Highlighted and plyPnlHighlight or plyPnlCol
			RNDX.Draw(plyPnlCorner, 0, 0, w, h, col, RNDX.SHAPE_CIRCLE)
			RNDX.DrawOutlined(plyPnlCorner, 0, 0, w, h, plyPnlBorder, off, RNDX.SHAPE_CIRCLE)

			return true
		end
	else
		pillPaint = function(s, w, h)
			draw.RoundedBox(plyPnlCorner, 0, 0, w, h, plyPnlBorder)

			if !isReplay and !IsValid(ply) then return false end

			local off = w * 0.01

			local col = s.Highlighted and plyPnlHighlight or plyPnlCol
			draw.RoundedBox(plyPnlCorner - off, off, off, w - (off * 2), h - (off * 2), col)

			return true
		end
	end

	slotPnl.Paint = function(s, w, h)
		if !pillPaint(s, w, h) then return end

		surface.SetTextColor(255, 255, 255, 255)
		surface.SetFont("GPTargetID")

		local txt = s.Text
		local ty = select(2, surface.GetTextSize(txt))

		surface.SetTextPos(w * 0.175, (h / 2) - (ty / 2))
		surface.DrawText(txt)
	end

	if isReplay or IsValid(ply) then
		slotPnl.Text = name

		if IsValid(ply) then
			local avh = scrh * 0.03

			local avPnl = vgui.Create("AvatarImage", slotPnl)
			avPnl:SetSize(avh, avh)
			avPnl:SetPos(slotPnl:GetWide() * 0.05, (slotPnl:GetTall() / 2) - scrh * 0.015)
			avPnl:SetPlayer(ply, avh)
			avPnl:SetPaintedManually(true)
		end
	end

	return slotPnl
end

local ssh16 = ScreenScaleH(16)
function GM:CreateMenuButton(txt, x, notButton)
	local scrw, scrh = ScrW(), ScrH()

	surface.SetFont("GPBold")
	local tx, ty = surface.GetTextSize(txt)
	local sizex = math.max(scrw * 0.2, tx + ssh16)

	local class = notButton and "DPanel" or "DButton"
	local start = vgui.Create(class, self.MenuPanel)
	start:SetPos((x or scrw * 0.875) - sizex, scrh * 0.825)
	start:SetSize(sizex, scrh * 0.075)
	start:SetText("")
	start:SetPaintedManually(true)

	start.Paint = function(s, w, h)
		local col = (!notButton and s:IsHovered()) and btnHover or plyPnlBorder
		if SHADERS then
			RNDX.Draw(ssh16, 0, 0, w, h, col, RNDX.SHAPE_FIGMA)

			RNDX.DrawMaterial(ssh16, 0, 0, w, h, btnHover, grad, RNDX.SHAPE_FIGMA)
		else
			draw.RoundedBox(ssh16, 0, 0, w, h, col)
		end

		surface.SetTextColor(255, 255, 255)
		surface.SetFont("GPBold")

		surface.SetTextPos((w / 2) - (tx / 2), (h / 2) - (ty / 2))

		surface.DrawText(txt)
	end

	return start
end

local check = "✓"
local grey = Color(128, 128, 128)
local settingTypes = {
	["checkbox"] = function(self, parent, idx)
		local data = self.Settings[idx]
		local cvar = data.cvar

		local pnl = vgui.Create("DButton", parent)
		data.pnl = pnl

		pnl:Dock(RIGHT)
		pnl:DockMargin(10, 0, 0, 0)
		pnl:SetWide(parent:GetTall())
		pnl:SetText("")
		pnl:SetPaintedManually(true)

		local convar = GetConVar(cvar)
		pnl.Highlighted = convar:GetBool()

		local greyData = data.grey
		if greyData then
			local newVal = greyData.val == convar:GetBool()
			local toGrey = greyData.cvars
			for i = 1, #toGrey do
				self.Settings[toGrey[i]].greyed = newVal
			end
		end

		pnl.Paint = function(s, w, h)
			local shouldGrey = data.greyed

			if SHADERS then
				RNDX.Draw(ScreenScaleH(5), 0, 0, w, h, shouldGrey and grey or color_white, RNDX.SHAPE_FIGMA)
			else
				draw.RoundedBox(ScreenScaleH(5), 0, 0, w, h, shouldGrey and grey or color_white)
			end

			if s.Highlighted then
				surface.SetFont("GPBold")
				surface.SetTextColor(0, 0, 0, 255)

				local tx, ty = surface.GetTextSize(check)
				surface.SetTextPos((w / 2) - (tx / 2), (h / 2) - (ty / 2))

				surface.DrawText(check)
			end
		end

		pnl.Think = function(s)
			pnl.Highlighted = convar:GetBool()
		end

		pnl.DoClick = function(s)
			if data.greyed then return end

			net.Start("GP_ChangeSetting")
				net.WriteUInt(idx - 1, bitsRequired(#self.Settings))
			net.SendToServer()

			if greyData then
				local newVal = greyData.val != convar:GetBool()
				local toGrey = greyData.cvars
				for i = 1, #toGrey do
					self.Settings[toGrey[i]].greyed = newVal
				end
			end
		end
	end,
	["num"] = function(self, parent, idx)
		local data = self.Settings[idx]
		local cvar = data.cvar

		local txt = vgui.Create("DButton", parent)
		txt:Dock(RIGHT)
		txt:SetWide(parent:GetTall())
		txt:SetFont("GPTextEntry")
		txt:SetText("")
		txt:SetPaintedManually(true)

		local convar = GetConVar(cvar)
		txt.Text = convar:GetInt()

		txt.Paint = function(s, w, h)
			local shouldGrey = data.greyed

			if SHADERS then
				RNDX.Draw(ScreenScaleH(5), 0, 0, w, h, shouldGrey and grey or color_white, RNDX.SHAPE_FIGMA)
			else
				draw.RoundedBox(ScreenScaleH(5), 0, 0, w, h, shouldGrey and grey or color_white)
			end

			local text = s.Text
			if text then
				surface.SetFont(s:GetFont())
				surface.SetTextColor(0, 0, 0, 255)

				local tx, ty = surface.GetTextSize(text)
				surface.SetTextPos((w / 2) - (tx / 2), (h / 2) - (ty / 2))

				surface.DrawText(text)
			end
		end

		local greyData = data.grey
		txt.DoClick = function(s)
			if data.greyed then return end

			Derma_StringRequest("", "Enter new value:", convar:GetString(), function(new)
				local val = tonumber(new)
				if !val then return end

				net.Start("GP_ChangeSetting")
					net.WriteUInt(idx - 1, bitsRequired(#self.Settings))
					net.WriteUInt(val, 32)
				net.SendToServer()

				txt.Text = val

				if greyData then
					local newVal = greyData.val == val
					local toGrey = greyData.cvars
					for i = 1, #toGrey do
						self.Settings[toGrey[i]].greyed = newVal
					end
				end
			end)
		end
	end
}

function GM:CreateLobbyScreen()
	local settingsPnl = select(2, self:TwoSidedMenu(false))

	if LocalPlayer():HasAuthority() then
		local start = self:CreateMenuButton("#GarryPhone.Go")
		start.DoClick = function()
			if !self.MenuOpen then return end

			self:StartGame()
		end

		for i = 1, #self.Settings do
			local data = self.Settings[i]

			local setting = vgui.Create("DPanel")
			setting:SetHeight(ScrH() * 0.05)
			setting.Paint = nil

			local label = vgui.Create("DLabel", setting)
			label:Dock(LEFT)
			label:SetFont("GPTargetID")
			label:SetText(language.GetPhrase("GarryPhone.Setting." .. data.name))
			label:SizeToContentsX()
			label:SetPaintedManually(true)

			settingTypes[data.type](self, setting, i)

			settingsPnl:AddItem(setting)
		end
	else
		self:CreateMenuButton("#GarryPhone.WaitingForHost", nil, true)
	end
end

local function SendPrompt(firstPrompt, pnl, txt)
	if !firstPrompt then
		pnl:SetMouseInputEnabled(false)
		pnl:SetKeyboardInputEnabled(false)
	end

	net.Start("GP_SendPrompt")
		net.WriteString(txt)
	net.SendToServer()
end

local examples = {
	"Breen",
	"Kleiner",
	"Barney",
	"Male07",
	"Eli",
	"Zombie",
	"GMan",
	"Grigori",
	"Mossman",
	"Alyx",
	"MingeBag",
	"John",
	"Hax",
	"CS4K",
	"sbox",
	"Liminal"
}

function GM:CreatePromptScreen()
	local firstPrompt = GetRound() == 1
	local scrw, scrh = ScrW(), ScrH()

	local parent
	if firstPrompt then
		self:CreateMenu(DrawPromptScreen)
		parent = self.MenuPanel
	end

	local pnl = vgui.Create("EditablePanel", parent)
	self.TextPanel = pnl

	if !parent then
		pnl:ParentToHUD()
	end

	pnl:SetSize(scrw * 0.6, scrh * 0.04)
	pnl:Center()

	pnl:MakePopup()

	local dtext = vgui.Create("DTextEntry", pnl)
	dtext:SetSize(scrw * 0.6, scrh * 0.04)
	dtext:SetFont("GPTextEntry")

	dtext:Center()

	if firstPrompt then
		pnl:SetPaintedManually(true)
		dtext:SetPaintedManually(true)
	else
		pnl:SetMouseInputEnabled(false)
		pnl:SetKeyboardInputEnabled(false)

		pnl:SetY(scrh * 0.95)
	end

	local menubtn = input.LookupBinding("+menu") or "not bound"
	local placeholder = firstPrompt and language.GetPhrase("GarryPhone.eg") .. " " .. language.GetPhrase("GarryPhone.Example." .. examples[math.random(#examples)]) or language.GetPhrase("GarryPhone.Type"):format(menubtn:upper())
	dtext:SetPlaceholderText(placeholder)

	dtext:SetMaximumCharCount(60)

	function dtext:Paint(w, h)
		local wep = LocalPlayer():GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "gmod_camera" then return end

		derma.SkinHook( "Paint", "TextEntry", self, w, h )
		return false
	end

	local backup = ""
	function dtext:OnLoseFocus()
		if !firstPrompt then
			pnl:SetMouseInputEnabled(false)
			pnl:SetKeyboardInputEnabled(false)
		end

		if self:GetText() != "" then
			SendPrompt(firstPrompt, pnl, backup)
		end
	end

	function dtext:OnEnter(txt)
		SendPrompt(firstPrompt, pnl, txt)
	end

	function dtext:OnChange()
		backup = self:GetText()
	end

	function dtext:OnRemove()
		SendPrompt(firstPrompt, pnl, backup)
	end
end

local maxplys = game.MaxPlayers()
local settingsTxt = "#GarryPhone.Settings"
function GM:TwoSidedMenu(isReplay)
	local scrw, scrh = ScrW(), ScrH()

	local py, ph
	if isReplay then
		py, ph = scrh * 0.15, scrh * 0.65
	else
		py, ph = scrh * 0.25, scrh * 0.55
	end

	local parent = vgui.Create("DPanel", self.MenuPanel)
	parent:SetPos(scrw * 0.125, py)
	parent:SetSize(scrw * 0.75, ph)
	parent.Paint = nil

	local plyParent = vgui.Create("DPanel", parent)
	plyParent:Dock(LEFT)
	plyParent:SetWide(scrw * 0.2)
	plyParent.Paint = nil

	local plyTitle = vgui.Create("DPanel", plyParent)
	plyTitle:Dock(TOP)
	plyTitle:SetTall(ph * 0.11)
	plyTitle:SetPaintedManually(true)
	plyTitle.Paint = function(s, w, h)
		if SHADERS then
			RNDX.Draw(ssh16, 0, 0, w, h, roundedBG, RNDX.SHAPE_FIGMA + RNDX.NO_TR + RNDX.NO_BR + RNDX.NO_BL)
		else
			draw.RoundedBoxEx(ssh16, 0, 0, w, h, roundedBG, true, false, false, false)
		end

		-- player title
		surface.SetTextColor(255, 255, 255, 255)
		surface.SetFont("GPTitle")

		local ply1, ply2
		if isReplay then
			ply1, ply2 = self.CurPly or 1, #self.Playing
		else
			ply1, ply2 = #select(2, player.Iterator()), maxplys
		end

		local txt = language.GetPhrase("GarryPhone.Players"):format(ply1, ply2)
		local th = select(2, surface.GetTextSize(txt))
		surface.SetTextPos(scrw * 0.01, (h / 2) - (th / 2))

		surface.DrawText(txt)
	end

	local plyPnl = vgui.Create("DPanelList", plyParent)
	plyPnl:Dock(BOTTOM)
	plyPnl:SetTall(ph * 0.885)
	plyPnl:SetSpacing(scrw * 0.005)
	plyPnl:SetPadding(scrw * 0.005)
	plyPnl:EnableVerticalScrollbar()
	plyPnl:SetPaintedManually(true)
	plyPnl.Paint = function(s, w, h)
		if SHADERS then
			RNDX.Draw(ssh16, 0, 0, w, h, roundedBG, RNDX.SHAPE_FIGMA + RNDX.NO_TR + RNDX.NO_BR + RNDX.NO_TL)
		else
			draw.RoundedBoxEx(ssh16, 0, 0, w, h, roundedBG, false, false, true, false)
		end
	end

	local plys = isReplay and self.Playing or select(2, player.Iterator())
	local plyCount = isReplay and #plys or game.MaxPlayers()

	if isReplay and !self.HighlightedPly then
		self.HighlightedPly = 1
		self.AlbumText = language.GetPhrase("GarryPhone.Album"):format(self.PlayerData[self.Playing[1]].name)
	end

	local plysDone = 0
	for i = 1, plyCount do
		local ply = isReplay and i or plys[i]
		local slotPnl = self:CreatePlayerPill(ply)

		if isReplay then
			plysDone = plysDone + 1
			if plysDone == self.HighlightedPly then
				slotPnl.Highlighted = true
			end
		end

		plyPnl:AddItem(slotPnl)
	end

	local replayParent = vgui.Create("DPanel", parent)
	replayParent:Dock(RIGHT)
	replayParent:SetWide(scrw * 0.525)
	replayParent.Paint = nil

	local replayTitle = vgui.Create("DPanel", replayParent)
	replayTitle:Dock(TOP)
	replayTitle:SetTall(ph * 0.11)
	replayTitle:SetPaintedManually(true)
	replayTitle.Paint = function(s, w, h)
		if SHADERS then
			RNDX.Draw(ssh16, 0, 0, w, h, roundedBG, RNDX.SHAPE_FIGMA + RNDX.NO_TL + RNDX.NO_BL + RNDX.NO_BR)
		else
			draw.RoundedBoxEx(ssh16, 0, 0, w, h, roundedBG, false, true, false, false)
		end

		-- settings title
		surface.SetTextColor(255, 255, 255, 255)
		surface.SetFont("GPTitle")

		local txt = isReplay and self.AlbumText or settingsTxt
		local th = select(2, surface.GetTextSize(txt))
		surface.SetTextPos(scrw * 0.01, (h / 2) - (th / 2))

		surface.DrawText(txt)
	end

	local replayPnl = vgui.Create("DPanelList", replayParent)
	replayPnl:Dock(BOTTOM)
	replayPnl:SetTall(ph * 0.885)
	replayPnl:SetPadding(scrw * 0.01)
	replayPnl:SetSpacing(scrw * 0.005)
	replayPnl:EnableVerticalScrollbar()
	replayPnl:SetPaintedManually(true)

	replayPnl.Paint = function(s, w, h)
		if SHADERS then
			RNDX.Draw(ssh16, 0, 0, w, h, roundedBG, RNDX.SHAPE_FIGMA + RNDX.NO_TL + RNDX.NO_BL + RNDX.NO_TR)
		else
			draw.RoundedBoxEx(ssh16, 0, 0, w, h, roundedBG, false, false, false, true)
		end
	end

	return plyPnl, replayPnl
end

function GM:StartGame()
	self.MenuOpen = false

	net.Start("GP_StartGame")
	net.SendToServer()
end

function GM:NewRound()
	self.PlayerData = {}
	self.Playing = {}

	local plys = select(2, player.Iterator())
	for i = 1, #plys do
		local ply = plys[i]
		if ply:Team() == TEAM_SPECTATOR then continue end

		local sid = ply:SteamID64()

		self.PlayerData[sid] = {ply = ply, name = ply:Nick()}
		table.insert(self.Playing, sid)
	end
end
net.Receive("GP_NewRound", function() GAMEMODE:NewRound() end)

local menuFuncs = {
	[STATE_LOBBY] = function(gm)
		gm.MenuOpen = !gm.MenuOpen

		if gm.MenuOpen then
			gm:CreateMenu(DrawLobbyScreen)
			gm:CreateLobbyScreen()
		else
			gm:KillMenuScreen()
		end

		return true
	end,
	[STATE_POST] = function(gm)
		if !LocalPlayer():HasAuthority() then return BaseClass.ScoreboardShow(gm) end

		gm.MenuOpen = !gm.MenuOpen

		if gm.MenuOpen then
			gm:CreateMenu()
			gm:CreatePostScreen()
		else
			gm:KillMenuScreen()
		end

		net.Start("GP_ShowResults")
			net.WriteBool(gm.MenuOpen)
		net.SendToServer()

		return true
	end
}

local function ScoreboardShow()
	local gm = GAMEMODE
	if !gm.MenuLock then
		local fn = menuFuncs[GetRoundState()]
		if fn then
			return fn(gm)
		end
	end
end

-- do this in a hook so that addons like lambda players don't break the menus
hook.Add("ScoreboardShow", "GP_ScoreboardShow", ScoreboardShow)

-- just in case
concommand.Add("gp_menu", ScoreboardShow)

function GM:OnPauseMenuShow()
	if self.MenuOpen and !self.MenuLock then
		self.MenuOpen = false
		self:KillMenuScreen()

		return false
	end
end