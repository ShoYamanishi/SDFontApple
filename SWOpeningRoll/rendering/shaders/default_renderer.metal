#include <metal_stdlib>
#include "render_uniforms.h"
#include "render_vertex_ins.h"
using namespace metal;

constant int VertexBufferIndexUniformPerScene    = 1;
constant int VertexBufferIndexUniformPerInstance = 2;
constant int FragmentBufferIndexUniformSDFont    = 4;
constant int TextureIndexSDFont                  = 3;

struct VertexOut {

    float4 position [[ position ]];
    float2 uv;

};

vertex VertexOut vertex_position_uv(

    const    VertexInPositionUV       vertex_in    [[ stage_in ]],
    constant UniformPerScene&         per_scene    [[ buffer( VertexBufferIndexUniformPerScene    ) ]],
    constant UniformPerInstance*      per_instance [[ buffer( VertexBufferIndexUniformPerInstance ) ]],
    const    ushort                   instance_id  [[ instance_id ]]
) {
    const float4 position =   per_scene.projection_matrix
                            * per_scene.view_matrix
                            * per_instance[instance_id].model_matrix
                            * vertex_in.position;

    const float2 uv = vertex_in.uv;

    VertexOut out {

        .position        = position,
        .uv              = uv
    };

    return out;
}

static inline float sdfont_step( const float v, const float pos )
{
    if ( v < pos ) {
        return 0.0;
    }
    else {
        return 1.0;
    }
}

static inline float sdfont_slope_step( const float v, const float width, const float pos )
{
    if ( v < pos - width * 0.5 ) {
        return 0.0;
    }
    else if (v < pos + width * 0.5 ) {
        return (v - ( pos - width * 0.5 ) ) / width;
    }
    else {
        return 1.0;
    }
}

static inline float sdfont_trapezoid( const float v, const float width, const float pos1, const float pos2 )
{
    if ( v < pos1 - width ) {
        return 0.0;
    }
    else if (v < pos1 ) {
        return (v - (pos1 - width))/width;
    }
    else if (v < pos2 ) {
        return 1.0;
    }
    else if (v < pos2 + width ) {
        return 1.0 - (v - pos2) /width;
    }
    else {
        return 0.0;
    }
}

static inline float sdfont_twin_peaks( const float v, const float width, const float pos1, const float pos2 )
{
    const float hw = 0.5 * width;

    if ( v < pos1 - hw ) {
        return 0.0;
    }
    else if (v < pos1 ) {
        return (v - (pos1 - hw)) / hw;
    }
    else if (v < pos1 + hw ) {
        return 1.0 - (v - pos1) / hw;
    }
    if ( v < pos2 - 0.5 * hw ) {
        return 0.0;
    }

    else if (v < pos2 ) {
        return (v - (pos2 - hw)) / hw;
    }
    else if (v < pos2 + hw ) {
        return 1.0 - (v - pos2) /hw;
    }
    else {
        return 0.0;
    }
}

static inline float sdfont_halo( const float v, const float width, const float pos1, const float pos2 )
{
    if (v > pos2) {
        return 0.0; // cutoff at pos2
    }
    else {
        return sdfont_slope_step( v, width, pos1 );
    }
}

fragment float4 fragment_sdfont(
    VertexOut                  in                 [[ stage_in ]],
    constant UniformSDFont&    sd_font            [[ buffer( FragmentBufferIndexUniformSDFont   ) ]],
    sampler                    texture_sampler    [[ sampler( 0 ) ]],
    texture2d<float>           texture_sdfont     [[ texture( TextureIndexSDFont ) ]]
) {
    float4 base_color = sd_font.foreground_color;

    float sampleDistance = texture_sdfont.sample(texture_sampler, in.uv).r;

    const auto func_type = (SDFontFunctionType)sd_font.func_type;

    float alpha = 0.0;

    switch (func_type) {

      case SDFONT_PASS_THROUGH:
        alpha = sampleDistance;
        break;

      case SDFONT_STEP:
        alpha = sdfont_step( sampleDistance, sd_font.point1 );
        break;

      case SDFONT_SMOOTH_STEP:
        alpha = smoothstep( sd_font.point1, sd_font.point2, sampleDistance );
        break;

      case SDFONT_SLOPE_STEP:
        alpha = sdfont_slope_step( sampleDistance, sd_font.width, sd_font.point1 );
        break;

      case SDFONT_TRAPEZOID:
        alpha = sdfont_trapezoid( sampleDistance, sd_font.width, sd_font.point1, sd_font.point2 );
        break;

      case SDFONT_TWIN_PEAKS:
        alpha = sdfont_twin_peaks( sampleDistance, sd_font.width, sd_font.point1, sd_font.point2 );
        break;

      case SDFONT_HALO:
        alpha = sdfont_halo( sampleDistance, sd_font.width, sd_font.point1, sd_font.point2 );
        break;


    }
    return float4(base_color.r, base_color.g, base_color.b, alpha * base_color.a );
}
