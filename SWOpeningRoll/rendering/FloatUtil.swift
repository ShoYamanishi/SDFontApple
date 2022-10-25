import simd

extension float4x4 {


    static func identity() -> float4x4 {
        matrix_identity_float4x4
    }
  
    init( fov: Float, aspect: Float, near: Float, far: Float,lhs: Bool = true ) {

        let y = 1 / tan(fov * 0.5)
        let x = y / aspect
        let z = lhs ? far / (far - near) : far / (near - far)
        let X = SIMD4<Float>(   x,    0.0,  0.0,  0.0)
        let Y = SIMD4<Float>( 0.0,      y,  0.0,  0.0)
        let Z = lhs ? SIMD4<Float>( 0.0,  0.0,            z,  1.0 ) : SIMD4<Float>( 0.0,  0.0,         z, -1.0 )
        let W = lhs ? SIMD4<Float>( 0.0,  0.0,  -1.0*near*z,  0.0 ) : SIMD4<Float>( 0.0,  0.0,  z * near,  0.0 )

        self.init()
        columns = ( X, Y, Z, W )
    }
}
