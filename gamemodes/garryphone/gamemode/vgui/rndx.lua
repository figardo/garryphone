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

local SHADERS_VERSION = "1.2"
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
