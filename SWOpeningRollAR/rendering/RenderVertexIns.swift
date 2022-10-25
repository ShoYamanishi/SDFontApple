import Foundation
import MetalKit

struct VertexInIndex {

    // MemoryLayout<VertexInIndex>.stride 4
    // MemoryLayout<VertexInIndex>.size 4
    // MemoryLayout<VertexInIndex>.alignment 4
    var index: Int32
    
    static func generateMTLBuffer( device: MTLDevice, indices : [Int32] ) -> MTLBuffer? {
        return device.makeBuffer(bytes: indices, length: MemoryLayout<Int32>.stride * indices.count, options: .storageModeShared )
    }
}

struct VertexInPositionUV {

    // MemoryLayout<VertexInPositionUV>.stride 32
    // MemoryLayout<VertexInPositionUV>.size 24
    // MemoryLayout<VertexInPositionUV>.alignment 16
    var position : SIMD4<Float>
    var uv :       SIMD2<Float>

    static func generateMTLBuffer( device: MTLDevice, positions : [SIMD4<Float>], uvs: [SIMD2<Float>] ) -> MTLBuffer? {
        var V : [Self] = []
        for i in 0 ..< positions.count {
            V.append( Self( position: positions[i], uv: uvs[i] ) )
        }
        return Self.generateMTLBuffer( device: device, vertices : V )
    }

    static func generateMTLBuffer( device: MTLDevice, vertices : [Self] ) -> MTLBuffer? {
        return device.makeBuffer(bytes: vertices, length: MemoryLayout<Self>.stride * vertices.count, options: .storageModeShared )
    }

}
