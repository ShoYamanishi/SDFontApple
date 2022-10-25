import Foundation
import MetalKit

extension MTLVertexDescriptor {

    static let float4Stride = MemoryLayout<SIMD4<Float>>.stride
    static let float3Stride = MemoryLayout<SIMD3<Float>>.stride
    static let float2Stride = MemoryLayout<SIMD2<Float>>.stride


    static func positionUV() -> MTLVertexDescriptor {

        let d = MTLVertexDescriptor()

        d.attributes[0].format      = .float4
        d.attributes[0].offset      = 0
        d.attributes[0].bufferIndex = 0

        d.attributes[1].format      = .float2
        d.attributes[1].offset      = float4Stride
        d.attributes[1].bufferIndex = 0

        d.layouts[0].stride         = float4Stride +  float4Stride
        d.layouts[0].stepFunction   = .perVertex

        return d
    }
}

