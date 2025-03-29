
AddCSLuaFile()
DEFINE_BASECLASS( "player_sandbox" )

local PLAYER = {}

function PLAYER:Loadout()
	self.Player:RemoveAllAmmo()

	self.Player:Give("gmod_tool")
	self.Player:Give("gmod_camera")
	self.Player:Give("weapon_physgun")

	self.Player:SwitchToDefaultWeapon()
end

function PLAYER:Spawn()
	BaseClass.Spawn( self )

	if self.Player.DiedAward then -- this is extremely retarded but it fixes SetPreventTransmit when players die/reconnect
		self.Player.DiedAward = false

		self.Player:Spawn()
	end

	self.Player:SetCustomCollisionCheck(true) -- disable player to player collisions
	self.Player:CollisionRulesChanged()

	local rs = GetRoundState()
	if rs == STATE_PROMPT or rs == STATE_BUILD then
		for _, ply in player.Iterator() do
			if ply == self.Player then continue end

			RecursiveSetPreventTransmit(self.Player, ply, true) -- put each player in their own realm
		end
	end
end

function PLAYER:Death()
	local rs = GetRoundState()
	if rs == STATE_PROMPT or rs == STATE_BUILD then
		self.Player.DiedAward = true
	end
end

player_manager.RegisterClass( "player_gphone", PLAYER, "player_sandbox" )
