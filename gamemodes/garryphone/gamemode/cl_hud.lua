DEFINE_BASECLASS("gamemode_base")

local function DrawBottomBar(scrw, scrh, height, bga, boa)
	bga = bga or 200
	boa = boa or 255

	surface.SetDrawColor(120, 0, 206, bga)

	local y = scrh * (1 - height)
	surface.DrawRect(0, y, scrw, scrh - y + 1)

	surface.SetDrawColor(255, 255, 255, boa)
	surface.DrawRect(0, y, scrw, scrh * 0.0025)
end

local timerFont = "GPBold"
local infiniteTime
local function DrawTimer(scrw, scrh)
	if !infiniteTime then
		infiniteTime = GetConVar("gp_infinitetime")
	end

	if infiniteTime:GetBool() then return end

	local time = math.ceil(math.max(0, GetRoundTime() - CurTime()))

	local timetext = string.ToMinutesSeconds(time)

	surface.SetFont(timerFont)
	local _, th = surface.GetTextSize(timetext)

	draw.SimpleText( timetext, timerFont, scrw / 2, (scrh * 0.1) - (th / 2), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end

function GM:CreateBuildText()
	local scrw, scrh = ScrW(), ScrH()

	local pnl = vgui.Create("DTextEntry")
	self.TextPanel = pnl
	pnl:ParentToHUD()
	pnl:SetSize(scrw * 0.6, scrh * 0.04)

	pnl:Center()
	pnl:SetY(scrh * 0.95)

	pnl:SetFont("GPTextEntry")

	pnl:SetEditable(false)
	pnl:SetText(self.CurPrompt or "")

	function pnl:Paint(w, h)
		if LocalPlayer():GetActiveWeapon():GetClass() == "gmod_camera" then return end

		derma.SkinHook( "Paint", "TextEntry", self, w, h )
		return false
	end
end

local statePaintFuncs = {
	[STATE_LOBBY] = function(gm)
		local txt = language.GetPhrase("GarryPhone.Welcome")

		local phrase = LocalPlayer():HasAuthority() and "GarryPhone.Configure" or "GarryPhone.Lobby"
		local key = input.LookupBinding("+showscores") or "not bound (scoreboard)"
		key = key:upper()

		txt = txt .. " " .. language.GetPhrase(phrase):format(key)

		return 0.05, txt
	end,
	[STATE_PROMPT] = function(gm)
		local plyteam = LocalPlayer():Team()
		if plyteam == TEAM_PLAYING then
			if GetRound() == 1 then
				if !gm.MenuOpen then gm.MenuOpen = true end
				return 0.05, nil, true
			else
				if gm.MenuOpen then gm.MenuOpen = false end
			end
		else
			gm.MenuOpen = false
			return 0.05, team.GetName(plyteam), true
		end

		return 0.1, "#GarryPhone.Describe", true
	end,
	[STATE_BUILD] = function(gm)
		if gm.MenuOpen then gm.MenuOpen = false end

		local plyteam = LocalPlayer():Team()
		if plyteam == TEAM_SPECTATOR then
			return 0.05, team.GetName(plyteam), true
		end

		local ent = gm.ReadyMark
		if IsValid(gm.ReadyMark) then
			local showspare1 = input.LookupBinding("gm_showspare1") or "NOT BOUND (gm_showspare1)"
			local text = language.GetPhrase("GarryPhone.Spawn"):format(showspare1)
			AddWorldTip( nil, text, nil, ent:GetPos(), ent )
		end

		return 0.1, "#GarryPhone.Build", true
	end,
	[STATE_POST] = function(gm)
		local ret1, ret2 = 0.05, gm.PostText

		local rdata = gm.RoundData
		if !rdata then return ret1, ret2 end

		rdata = gm.RoundData[gm.CurPly]
		if !rdata then return ret1, ret2 end

		local lastdata = #rdata
		if lastdata < 3 or lastdata % 2 == 0 then return ret1, ret2 end

		local ent = rdata[lastdata - 1].data
		if !ent or !IsValid(ent) or !isentity(ent) then return ret1, ret2 end

		local data = rdata[lastdata]
		local author = isentity(data.author) and data.author:Nick() or data.author
		local text = language.GetPhrase("GarryPhone.ThoughtThisWas"):format(author, data.data)

		AddWorldTip( nil, text, nil, ent:GetPos(), ent )
	end
}

local statePostPaintFuncs = {
	[STATE_BUILD] = function(gm, scrw, scrh)
		if LocalPlayer():Team() == TEAM_SPECTATOR then return end

		local showspare2 = input.LookupBinding("gm_showspare2") or "not bound (gm_showspare2)"
		local txt = language.GetPhrase("GarryPhone.Ready") .. " (" .. showspare2:upper() .. ") " .. (gm.Ready and "[✓]" or "[ ]")

		surface.SetTextColor(255, 255, 255, 255)
		surface.SetFont("GPTargetID")
		local tx, ty = surface.GetTextSize(txt)
		surface.SetTextPos((scrw * 0.9) - (tx / 2), (scrh * 0.95) - (ty / 2))

		surface.DrawText(txt)
	end
}

local lobbyDelta = 0
function GM:HUDPaintBackground()
	local scrw, scrh = ScrW(), ScrH()

	local rs = GetRoundState()
	local h, txt, time = statePaintFuncs[rs](self)
	if !h then return end

	local diff = FrameTime()
	if !self.MenuOpen then diff = -diff end

	lobbyDelta = math.Clamp(lobbyDelta + diff, 0, 1)
	local lobbyDeltaEased = math.EaseInOut(lobbyDelta)

	self.MenuBarHeight = Lerp(lobbyDeltaEased, h, 1)

	local alpha = Lerp(lobbyDeltaEased, 255, 0)
	DrawBottomBar(scrw, scrh, self.MenuBarHeight, Lerp(lobbyDeltaEased, 200, 255), alpha)

	if txt then
		surface.SetFont("GPTargetID")
		surface.SetTextColor(255, 255, 255, alpha)

		local tw, th = surface.GetTextSize(txt)
		local x = (scrw / 2) - (tw / 2)
		local y = (scrh * (1 - h + 0.025)) - (th / 2)
		surface.SetTextPos(x, y)

		surface.DrawText(txt)
	end

	if time then
		DrawTimer(scrw, scrh)
	end

	if statePostPaintFuncs[rs] then
		statePostPaintFuncs[rs](self, scrw, scrh)
	end
end

function GM:HUDDrawTargetID()
	local tr = util.GetPlayerTrace( LocalPlayer() )
	local trace = util.TraceLine( tr )
	if !trace.Hit or !trace.HitNonWorld or !trace.Entity:IsPlayer() then return end

	local text = trace.Entity:Nick()
	local font = "GPTargetID"

	surface.SetFont( font )
	local w = surface.GetTextSize( text )

	local MouseX, MouseY = input.GetCursorPos()

	if ( MouseX == 0 and MouseY == 0 or !vgui.CursorVisible() ) then
		MouseX = ScrW() / 2
		MouseY = ScrH() / 2
	end

	local x = MouseX
	local y = MouseY

	x = x - w / 2
	y = y + 30

	-- The fonts internal drop shadow looks lousy with AA on
	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ) )
	draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ) )
	draw.SimpleText( text, font, x, y, color_white )
end

function GM:SpawnMenuOpen()
	local rs = GetRoundState()
	if rs == STATE_LOBBY or rs == STATE_BUILD then return true end

	if rs == STATE_PROMPT and GetRound() != 1 then
		local pnl = self.TextPanel
		if IsValid(pnl) then
			pnl:MakePopup()

			pnl:GetChild(0):RequestFocus()
		end
	end

	return false
end

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true
}
function GM:HUDShouldDraw(name)
	if hide[name] then
		return false
	end

	if name == "CHudCrosshair" and self.MenuOpen then return false end

	return BaseClass.HUDShouldDraw(self, name)
end