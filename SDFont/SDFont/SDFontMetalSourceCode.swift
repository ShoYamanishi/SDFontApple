let SDFontMetalSourceCode = """
#include <metal_stdlib>
using namespace metal;

typedef struct _ConfigGen {
    int   draw_area_side_len; // number of pixels per row.
    float spread_thickness;   // it detemines the rectangular area for searching signed distance.
    int   width;              // width of the glyph including the spread.
    int   height;             // height of the glyph including the spread.
} ConfigGen;


// Brute-force signed-distance finder. Each pixel gets one thread to calculate
// the signed distance (distance from the closest pixel of the different value.)
// Interpretation of the output float value:
// * 0.5 <= v  : the pixel is inside the glyph and v is the distance to the closest pixel outside the glyph
// * -0.5 >= v : the pixel is outside the glyph and v is the distance to the closest pixel inside the glyph
kernel void generate_signed_distance (
    device const ConfigGen& config        [[ buffer(0)]],
    device const uint8_t*   pixmap_buffer [[ buffer(1)]],
    device       float*     sd_buffer     [[ buffer(2)]],
    const        uint       tid           [[ thread_position_in_grid ]]
) {
    if ( (int)tid < config.width * config.height ) {

        const int base_i = tid % config.width;
        const int base_j = tid / config.width;

        const int v = pixmap_buffer[ base_j * config.draw_area_side_len + base_i ];
        const int spread = (int)config.spread_thickness;

        float sq_dist_min = (float)config.draw_area_side_len * (float)config.draw_area_side_len * 4.0; // arbitrary large value

        for ( int j = -1 * spread; j < spread; j++ ) {

            if ( base_j + j >= 0 && base_j + j < config.height ) {

                for ( int i = -1 * spread; i < spread; i++ ) {

                    if ( base_i + i >= 0 && base_i + i < config.width ) {

                        if ( (i != 0) || (j != 0) ) {

                            const int v_other = pixmap_buffer[ ( base_j + j ) * config.draw_area_side_len + base_i + i ];

                            if ( ( v >= 128 && v_other < 128 ) || ( v < 128 && v_other >= 128 ) ) {

                                const float sq_dist = (float)( i * i + j * j );

                                if ( sq_dist_min > sq_dist ) {
                                    sq_dist_min = sq_dist;
                                }
                            }
                        }
                    }
                }
            }
        }

        const float normalized_min_dist = ( /*precise::*/sqrt(sq_dist_min) - 1.0 ) / config.spread_thickness;
        if ( v >= 128 ) {
            // inside glyph
            sd_buffer[ base_j * config.draw_area_side_len + base_i ] = 0.5 + normalized_min_dist / 2.0;
        }
        else {
            // outside glyph
            sd_buffer[ base_j * config.draw_area_side_len + base_i ] = 0.5 - normalized_min_dist / 2.0;
        }
    }
}

typedef struct _ConfigDownsample {

    // glyph-local upsampled space
    int   side_len_src;
    int   width_src;
    int   height_src;

    // output texture space
    int   side_len_dst;
    int   width_dst;
    int   height_dst;
    int   origin_x_dst;
    int   origin_y_dst;

    int   upsampling_factor;
    float spread_thickness;
    
    int   flip_y;

} ConfigDownsample;


// Each output value in uint8 is calculated from the square region of the upsampled signed distance values,
// whose side length is config.upsampling_factor.
// The output value is the average of the square resion, re-scaled to the down-sampled space.
kernel void downsample (
    device const ConfigDownsample& config        [[ buffer(0)]],
    device const float*            sd_buffer_src [[ buffer(1)]],
    device       uint8_t*          sd_buffer_dst [[ buffer(2)]],
    const        uint              tid           [[ thread_position_in_grid ]]
) {
    if ( (int)tid < config.width_dst * config.height_dst ) {

        const int i_dst = tid % config.width_dst;
        const int j_dst = tid / config.width_dst;

        const int base_i_src = i_dst * config.upsampling_factor;
        const int base_j_src = j_dst * config.upsampling_factor;

        const float sd_in_upsampled = sd_buffer_src[ base_j_src * config.side_len_src + base_i_src ];
        const long  quantized_sd = (long)( sd_in_upsampled * 256.0 );
        const long  clamped_sd   = max( (long)0, ( min( (long)255, quantized_sd ) ) );

        if ( config.flip_y ) {

            sd_buffer_dst[ ( ( config.side_len_dst - 1 ) - ( config.origin_y_dst + j_dst ) ) * config.side_len_dst + config.origin_x_dst + i_dst ] = (uint8_t)clamped_sd;
        }
        else {
            sd_buffer_dst[ (config.origin_y_dst + j_dst) * config.side_len_dst + config.origin_x_dst + i_dst ] = (uint8_t)clamped_sd;
        }
    }
}


typedef struct _ConfigZeroInitialize {
    int length_in_int32;
} ConfigZeroInitialize;

kernel void initialize_with_zero (
    device const ConfigZeroInitialize& config                  [[ buffer(0)]],
    device       int*                  buf                     [[ buffer(1)]],
    const        uint                  tid                     [[ thread_position_in_grid ]],
    const        uint                  threads_per_threadgroup [[ threads_per_threadgroup ]]
) {
    for( int i = tid; i < config.length_in_int32 ; i += threads_per_threadgroup ) {
        buf[i] = 0;
    }
}
"""
