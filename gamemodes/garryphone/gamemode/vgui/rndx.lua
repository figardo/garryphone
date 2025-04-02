--[[
Copyright (c) 2025 Srlion (https://github.com/Srlion)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

if SERVER then
	AddCSLuaFile()
	return
end

local bit_band = bit.band
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRectUV = surface.DrawTexturedRectUV
local surface_DrawTexturedRect = surface.DrawTexturedRect
local render_UpdateScreenEffectTexture = render.UpdateScreenEffectTexture
local math_min = math.min
local math_max = math.max
local DisableClipping = DisableClipping

local SHADERS_VERSION = "gphone.1"
local SHADERS_GMA = [========[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]========]
do
	local DECODED_SHADERS_GMA = util.Base64Decode(SHADERS_GMA)
	if not DECODED_SHADERS_GMA or #DECODED_SHADERS_GMA == 0 then
		print("Failed to load shaders!") -- this shouldn't happen
		return
	end

	file.Write("rndx_shaders_" .. SHADERS_VERSION .. ".gma", DECODED_SHADERS_GMA)
	game.MountGMA("data/rndx_shaders_" .. SHADERS_VERSION .. ".gma")
end

local function GET_SHADER(name)
	return SHADERS_VERSION:gsub("%.", "_") .. "_" .. name
end

-- These are constants from common_rounded.hlsl file
local C_RADIUS_X, C_RADIUS_Y, C_RADIUS_W, C_RADIUS_Z = "$c0_x", "$c0_y", "$c0_w", "$c0_z"

local C_SIZE_W, C_SIZE_H = "$c1_x", "$c1_y"

local C_POWER_PARAM = "$c1_z"
local C_USE_TEXTURE = "$c1_w"
local C_OUTLINE_THICKNESS = "$c2_x"
local C_AA = "$c2_y"
--

-- I know it exists in gmod, but I want to have math.min and math.max localized
local function math_clamp(val, min, max)
	return math_min(math_max(val, min), max)
end

local NEW_FLAG; do
	local flags_n = -1
	function NEW_FLAG()
		flags_n = flags_n + 1
		return 2 ^ flags_n
	end
end

local NO_TL, NO_TR, NO_BL, NO_BR           = NEW_FLAG(), NEW_FLAG(), NEW_FLAG(), NEW_FLAG()

-- Svetov/Jaffies's great idea!
local SHAPE_CIRCLE, SHAPE_FIGMA, SHAPE_IOS = NEW_FLAG(), NEW_FLAG(), NEW_FLAG()

local BLUR                                 = NEW_FLAG()

local RNDX                                 = {}

local shader_mat                           = [==[
screenspace_general
{
	$pixshader ""
	$vertexshader ""

	$basetexture ""
	$texture1    ""
	$texture2    ""
	$texture3    ""

	// Mandatory, don't touch
	$ignorez            1
	$vertexcolor        1
	$vertextransform    1
	"<dx90"
	{
		$no_draw 1
	}

	$copyalpha                 0
	$alpha_blend_color_overlay 0
	$alpha_blend               1 // for AA
	$linearwrite               1 // to disable broken gamma correction for colors
	$linearread_basetexture    1 // to disable broken gamma correction for textures
}
]==]

local function create_shader_mat(name, opts)
	assert(name and isstring(name), "create_shader_mat: tex must be a string")

	local key_values = util.KeyValuesToTable(shader_mat, false, true)

	if opts then
		for k, v in pairs(opts) do
			key_values[k] = v
		end
	end

	local mat = CreateMaterial(
		"rndx_shaders1" .. name .. SysTime(),
		"screenspace_general",
		key_values
	)

	return mat
end

local ROUNDED_MAT = create_shader_mat("rounded", {
	["$pixshader"] = GET_SHADER("rndx_rounded_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	[C_USE_TEXTURE] = 0, -- no texture
})

-- garry phoney work
local ROUNDED_INV_MAT = create_shader_mat("rounded_inv", {
	["$pixshader"] = GET_SHADER("rndx_rounded_inv_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	[C_USE_TEXTURE] = 0, -- no texture
})

local ROUNDED_TEXTURE_MAT = create_shader_mat("rounded_texture", {
	["$pixshader"] = GET_SHADER("rndx_rounded_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = "loveyoumom", -- if there is no base texture, you can't change it later
	[C_USE_TEXTURE] = 1,          -- this indicates that we have a texture
})

local BLUR_H_MAT = create_shader_mat("blur_horizontal", {
	["$pixshader"] = GET_SHADER("rndx_rounded_bh_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = "_rt_FullFrameFB",
})
local BLUR_V_MAT = create_shader_mat("blur_vertical", {
	["$pixshader"] = GET_SHADER("rndx_rounded_bv_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = "_rt_FullFrameFB",
})

local SHADOWS_MAT = create_shader_mat("rounded_shadows", {
	["$pixshader"] = GET_SHADER("rndx_shadows_ps20b"),
	[C_USE_TEXTURE] = 0, -- no texture
})

local SHADOWS_BLUR_H_MAT = create_shader_mat("shadows_blur_horizontal", {
	["$pixshader"] = GET_SHADER("rndx_shadows_bh_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = "_rt_FullFrameFB",
})
local SHADOWS_BLUR_V_MAT = create_shader_mat("shadows_blur_vertical", {
	["$pixshader"] = GET_SHADER("rndx_shadows_bv_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = "_rt_FullFrameFB",
})

local SHAPES = {
	[SHAPE_CIRCLE] = 2,
	[SHAPE_FIGMA] = 2.2,
	[SHAPE_IOS] = 4,
}

local SetMatFloat = ROUNDED_MAT.SetFloat
local SetMatTexture = ROUNDED_MAT.SetTexture

local DEFAULT_DRAW_FLAGS = SHAPE_FIGMA

local function draw_rounded(x, y, w, h, col, flags, tl, tr, bl, br, texture, thickness)
	if col and col.a == 0 then
		return
	end

	if not flags then
		flags = DEFAULT_DRAW_FLAGS
	end

	local mat = ROUNDED_MAT

	local using_blur = bit_band(flags, BLUR) ~= 0
	if using_blur then
		RNDX.DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
		return
	end

	if texture then
		mat = ROUNDED_TEXTURE_MAT
		SetMatTexture(mat, "$basetexture", texture)
	end

	if tl < 0 then
		mat = ROUNDED_INV_MAT
		tl = math.abs(tl)
		tr = math.abs(tr)
		bl = math.abs(bl)
		br = math.abs(br)
	end

	SetMatFloat(mat, C_SIZE_W, w)
	SetMatFloat(mat, C_SIZE_H, h)

	-- Roundness
	local max_rad = math_min(w, h) / 2
	SetMatFloat(mat, C_RADIUS_W, bit_band(flags, NO_TL) == 0 and math_clamp(tl, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_Z, bit_band(flags, NO_TR) == 0 and math_clamp(tr, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_X, bit_band(flags, NO_BL) == 0 and math_clamp(bl, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_Y, bit_band(flags, NO_BR) == 0 and math_clamp(br, 0, max_rad) or 0)
	--

	SetMatFloat(mat, C_OUTLINE_THICKNESS, thickness or -1) -- no outline = -1

	local shape_value = SHAPES[bit_band(flags, SHAPE_CIRCLE + SHAPE_FIGMA + SHAPE_IOS)]
	SetMatFloat(mat, C_POWER_PARAM, shape_value or 2.2)

	if col then
		surface_SetDrawColor(col.r, col.g, col.b, col.a)
	else
		surface_SetDrawColor(255, 255, 255, 255)
	end

	surface_SetMaterial(mat)
	-- https://github.com/Jaffies/rboxes/blob/main/rboxes.lua
	-- fixes setting $basetexture to ""(none) not working correctly
	surface_DrawTexturedRectUV(x, y, w, h, -0.015625, -0.015625, 1.015625, 1.015625)
end

function RNDX.Draw(r, x, y, w, h, col, flags)
	draw_rounded(x, y, w, h, col, flags, r, r, r, r)
end

function RNDX.DrawOutlined(r, x, y, w, h, col, thickness, flags)
	draw_rounded(x, y, w, h, col, flags, r, r, r, r, nil, thickness or 1)
end

function RNDX.DrawTexture(r, x, y, w, h, col, texture, flags)
	draw_rounded(x, y, w, h, col, flags, r, r, r, r, texture)
end

function RNDX.DrawMaterial(r, x, y, w, h, col, mat, flags)
	local tex = mat:GetTexture("$basetexture")
	if tex then
		RNDX.DrawTexture(r, x, y, w, h, col, tex, flags)
	end
end

function RNDX.DrawCircle(x, y, r, col, flags)
	RNDX.Draw(r / 2, x - r / 2, y - r / 2, r, r, col, (flags or 0) + SHAPE_CIRCLE)
end

function RNDX.DrawCircleOutlined(x, y, r, col, thickness, flags)
	RNDX.DrawOutlined(r / 2, x - r / 2, y - r / 2, r, r, col, thickness, (flags or 0) + SHAPE_CIRCLE)
end

function RNDX.DrawCircleTexture(x, y, r, col, texture, flags)
	RNDX.DrawTexture(r / 2, x - r / 2, y - r / 2, r, r, col, texture, (flags or 0) + SHAPE_CIRCLE)
end

function RNDX.DrawCircleMaterial(x, y, r, col, mat, flags)
	RNDX.DrawMaterial(r / 2, x - r / 2, y - r / 2, r, r, col, mat, (flags or 0) + SHAPE_CIRCLE)
end

local DRAW_SECOND_BLUR = false
local USE_SHADOWS_BLUR = false
function RNDX.DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
	if not flags then
		flags = DEFAULT_DRAW_FLAGS
	end

	local mat; if DRAW_SECOND_BLUR then
		mat = USE_SHADOWS_BLUR and SHADOWS_BLUR_H_MAT or BLUR_H_MAT
	else
		mat = USE_SHADOWS_BLUR and SHADOWS_BLUR_V_MAT or BLUR_V_MAT
	end

	SetMatFloat(mat, C_SIZE_W, w)
	SetMatFloat(mat, C_SIZE_H, h)

	-- Roundness
	local max_rad = math_min(w, h) / 2
	SetMatFloat(mat, C_RADIUS_W, bit_band(flags, NO_TL) == 0 and math_clamp(tl, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_Z, bit_band(flags, NO_TR) == 0 and math_clamp(tr, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_X, bit_band(flags, NO_BL) == 0 and math_clamp(bl, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_Y, bit_band(flags, NO_BR) == 0 and math_clamp(br, 0, max_rad) or 0)
	--

	SetMatFloat(mat, C_OUTLINE_THICKNESS, thickness or -1) -- no outline = -1

	local shape_value = SHAPES[bit_band(flags, SHAPE_CIRCLE + SHAPE_FIGMA + SHAPE_IOS)]
	SetMatFloat(mat, C_POWER_PARAM, shape_value or 2.2)

	render_UpdateScreenEffectTexture() -- we need this otherwise anything that is being drawn before will not be drawn

	surface_SetDrawColor(255, 255, 255, 255)
	surface_SetMaterial(mat)
	surface_DrawTexturedRect(x, y, w, h)

	if not DRAW_SECOND_BLUR then
		DRAW_SECOND_BLUR = true
		RNDX.DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
		DRAW_SECOND_BLUR = false
	end
end

function RNDX.DrawShadowsEx(x, y, w, h, col, flags, tl, tr, bl, br, spread, intensity, thickness)
	if col and col.a == 0 then
		return
	end

	if not flags then
		flags = DEFAULT_DRAW_FLAGS
	end

	local using_blur = bit_band(flags, BLUR) ~= 0

	-- Shadows are a bit bigger than the actual box
	spread = spread or 30
	intensity = intensity or spread * 1.2

	x = x - spread
	y = y - spread
	w = w + (spread * 2)
	h = h + (spread * 2)

	tl = tl + (spread * 2)
	tr = tr + (spread * 2)
	bl = bl + (spread * 2)
	br = br + (spread * 2)
	--

	local mat = SHADOWS_MAT
	SetMatFloat(mat, C_SIZE_W, w)
	SetMatFloat(mat, C_SIZE_H, h)

	-- Roundness
	local max_rad = math_min(w, h) / 2
	SetMatFloat(mat, C_RADIUS_W, bit_band(flags, NO_TL) == 0 and math_clamp(tl, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_Z, bit_band(flags, NO_TR) == 0 and math_clamp(tr, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_X, bit_band(flags, NO_BL) == 0 and math_clamp(bl, 0, max_rad) or 0)
	SetMatFloat(mat, C_RADIUS_Y, bit_band(flags, NO_BR) == 0 and math_clamp(br, 0, max_rad) or 0)
	--

	SetMatFloat(mat, C_OUTLINE_THICKNESS, thickness or -1) -- no outline = -1
	SetMatFloat(mat, C_AA, intensity)                   -- AA

	local shape_value = SHAPES[bit_band(flags, SHAPE_CIRCLE + SHAPE_FIGMA + SHAPE_IOS)]
	SetMatFloat(mat, C_POWER_PARAM, shape_value or 2.2)

	-- if we are inside a panel, we need to draw outside of it
	local old_clipping_state = DisableClipping(true)

	if using_blur then
		USE_SHADOWS_BLUR = true
		SetMatFloat(SHADOWS_BLUR_H_MAT, C_AA, intensity) -- AA
		SetMatFloat(SHADOWS_BLUR_V_MAT, C_AA, intensity) -- AA
		RNDX.DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
		USE_SHADOWS_BLUR = false
	end

	if col then
		surface_SetDrawColor(col.r, col.g, col.b, col.a)
	else
		surface_SetDrawColor(0, 0, 0, 255)
	end

	surface_SetMaterial(mat)
	-- https://github.com/Jaffies/rboxes/blob/main/rboxes.lua
	-- fixes having no $basetexture causing uv to be broken
	surface_DrawTexturedRectUV(x, y, w, h, -0.015625, -0.015625, 1.015625, 1.015625)

	DisableClipping(old_clipping_state)
end

function RNDX.DrawShadows(r, x, y, w, h, col, spread, intensity, flags)
	RNDX.DrawShadowsEx(x, y, w, h, col, flags, r, r, r, r, spread, intensity)
end

-- Flags
RNDX.NO_TL = NO_TL
RNDX.NO_TR = NO_TR
RNDX.NO_BL = NO_BL
RNDX.NO_BR = NO_BR

RNDX.SHAPE_CIRCLE = SHAPE_CIRCLE
RNDX.SHAPE_FIGMA = SHAPE_FIGMA
RNDX.SHAPE_IOS = SHAPE_IOS

RNDX.BLUR = BLUR

function RNDX.SetFlag(flags, flag, bool)
	flag = RNDX[flag] or flag
	if tobool(bool) then
		return bit.bor(flags, flag)
	else
		return bit.band(flags, bit.bnot(flag))
	end
end

return RNDX
