import Foundation
import MetalKit

struct UniformPerInstance {

    // MemoryLayout<UniformPerInstancel>.stride 64
    // MemoryLayout<UniformPerInstance>.size 64
    // MemoryLayout<UniformPerInstance>.alignment 16

    var modelMatrix  : float4x4

    public init ( modelMatrix: matrix_float4x4 ) {
        self.modelMatrix  = modelMatrix
    }

    public init () {
        modelMatrix  = matrix_identity_float4x4
    }

    static func generateMTLBuffer( device: MTLDevice, instances : [Self] ) -> MTLBuffer? {
        return device.makeBuffer(bytes: instances, length: MemoryLayout<Self>.stride * instances.count, options: .storageModeShared )
    }

    static func updateMTLBuffer( buffer : MTLBuffer, instances : [Self] ) {
        buffer.contents().copyMemory( from: instances, byteCount: MemoryLayout<Self>.stride * instances.count )
    }
}

struct UniformPerScene {

    // MemoryLayout<UniformPerScene>.stride 160
    // MemoryLayout<UniformPerScene>.size 148
    // MemoryLayout<UniformPerScene>.alignment 16

    var viewMatrix       : float4x4
    var projectionMatrix : float4x4
    var cameraPosition   : SIMD3<Float>
    var numLights        : Int32

    public init( viewMatrix: float4x4, projectionMatrix: float4x4, cameraPosition : SIMD3<Float>, numLights: Int ) {
        self.viewMatrix       = viewMatrix
        self.projectionMatrix = projectionMatrix
        self.cameraPosition   = cameraPosition
        self.numLights        = Int32(numLights)
    }

    public init() {
        viewMatrix       = matrix_identity_float4x4
        projectionMatrix = matrix_identity_float4x4
        cameraPosition   = SIMD3<Float>( 0.0, 0.0, 0.0 )
        self.numLights   = 0
    }

    mutating func update( camera: Camera ) {
        viewMatrix       = camera.viewMatrixLHS
        projectionMatrix = camera.projectionMatrix
    }
    
    static func generateMTLBuffer( device: MTLDevice, uniformPerScene : inout Self ) -> MTLBuffer? {
        return device.makeBuffer(bytes: &uniformPerScene, length: MemoryLayout<Self>.stride, options: .storageModeShared )
    }

    static func updateMTLBuffer( buffer : MTLBuffer, uniformPerScene : inout Self ) {
        buffer.contents().copyMemory( from: &uniformPerScene, byteCount: MemoryLayout<Self>.stride )
    }
}


struct UniformSDFont {

    enum FunctionType : Int32 {
        case SDFONT_PASS_THROUGH = 0
        case SDFONT_STEP         = 1
        case SDFONT_SMOOTH_STEP  = 2
        case SDFONT_SLOPE_STEP   = 3
        case SDFONT_TRAPEZOID    = 4
        case SDFONT_TWIN_PEAKS   = 5
        case SDFONT_HALO         = 6
    }

    var foregroundColor : SIMD4<Float>
    var funcType        : Int32
    var width           : Float
    var point1          : Float
    var point2          : Float

    init(
        foregroundColor : SIMD4<Float>,
        funcType        : FunctionType,
        point1          : Float,
        point2          : Float,
        width           : Float
    ) {
        self.foregroundColor = foregroundColor
        self.funcType        = funcType.rawValue
        self.width           = width
        self.point1          = point1
        self.point2          = point2
    }

    init() {
        self.foregroundColor = SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
        self.funcType        = FunctionType.SDFONT_PASS_THROUGH.rawValue
        self.width           = 0
        self.point1          = 0
        self.point2          = 0
    }

    static func generateMTLBuffer( device: MTLDevice, v : inout Self ) -> MTLBuffer? {
        return device.makeBuffer(bytes: &v, length: MemoryLayout<Self>.stride, options: .storageModeShared )
    }

    static func updateMTLBuffer( buffer : MTLBuffer, v : inout Self ) {
        buffer.contents().copyMemory( from: &v, byteCount: MemoryLayout<Self>.stride )
    }
}

