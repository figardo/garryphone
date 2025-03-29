-- TODO: finish this
GM.Gamemodes = {
	["default"] = {
		-- order func determines which rounds will be prompts and which will be builds
		-- return false for prompt, true for build
		order = function(round, total) -- round = current position in rounddata, total = total playercount
			return round % 2 == 0 -- alternates between prompt and build, starting with prompt
		end
	},
	["sandwich"] = {
		order = function(round, total)
			return round != 1 and round != total
		end
	}
}