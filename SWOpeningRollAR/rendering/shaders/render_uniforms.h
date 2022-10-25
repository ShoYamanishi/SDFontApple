#ifndef __RENDER_UNIFORMS_H__
#define __RENDER_UNIFORMS_H__

using namespace metal;

struct UniformPerInstance {

    // MemoryLayout<UniformPerInstancel>.stride 64
    // MemoryLayout<UniformPerInstance>.size 64
    // MemoryLayout<UniformPerInstance>.alignment 16

    float4x4 model_matrix; // size 64, alignment 16
};

struct UniformPerScene {

    // MemoryLayout<UniformPerScene>.stride 160
    // MemoryLayout<UniformPerScene>.size 148
    // MemoryLayout<UniformPerScene>.alignment 16

    float4x4 view_matrix;       // size 64, alignment 16
    float4x4 projection_matrix; // size 64, alignment 16
    float3   camera_position;   // size 16, alignment 16
    int32_t  num_lights;        // size 4, alignment 4
    int32_t  _padding_01_;      // size 4, alignment 4
    int32_t  _padding_02_;      // size 4, alignment 4
    int32_t  _padding_03_;      // size 4, alignment 4
};

typedef enum {

    SDFONT_PASS_THROUGH = 0,
    SDFONT_STEP         = 1,
    SDFONT_SMOOTH_STEP  = 2,
    SDFONT_SLOPE_STEP   = 3,
    SDFONT_TRAPEZOID    = 4,
    SDFONT_TWIN_PEAKS   = 5,
    SDFONT_HALO         = 6

} SDFontFunctionType;


struct UniformSDFont {
    float4 foreground_color;
    int    func_type;
    float  width;
    float  point1;
    float  point2;
};


#endif /* __RENDER_UNIFORMS_H__ */
