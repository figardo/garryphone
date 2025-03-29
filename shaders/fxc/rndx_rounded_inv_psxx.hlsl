// the files required to build this can be found here https://github.com/Srlion/RNDX
#include "common_rounded.hlsl"

// slightly modified version of https://github.com/Srlion/RNDX/blob/master/src/rndx_rounded_psxx.hlsl
float4 main(PS_INPUT i) : COLOR {
    float alpha = 1.0 - (calculate_rounded_alpha(i));
    float4 rect_color = USE_TEXTURE == 1 ? tex2D(TexBase, i.uv.xy) * i.color : i.color;

    if (alpha == 0.0)
        discard;

    return float4(rect_color.rgb, rect_color.a * alpha);
}
