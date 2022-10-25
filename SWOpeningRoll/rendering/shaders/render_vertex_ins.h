#ifndef __RENDER_VERTEX_INS_H__
#define __RENDER_VERTEX_INS_H__

struct VertexInPositionUV {

    // MemoryLayout<VertexInPositionUV>.stride 32
    // MemoryLayout<VertexInPositionUV>.size 24
    // MemoryLayout<VertexInPositionUV>.alignment 16

    float4 position  [[ attribute( 0 ) ]]; // size 16, alignment 16

    float2 uv        [[ attribute( 1 ) ]]; // size 8, alignment 8

    //float  _padding_01_;                 // size 4, alignment 4
    //float  _padding_02_;                 // size 4, alignment 4
};

#endif /*__RENDER_VERTEX_INS_H__*/
