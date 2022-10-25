import Foundation

import simd

class Camera {

    var fov             : Float        =    0.3 * Float.pi
    var aspect          : Float        =    1.0
    var near            : Float        =    0.01 // Do not make this too small, otherwise the depth buffer gets messed up
    var far             : Float        = 1000.0  // Do not make this too large, otherwise the depth buffer gets messed up

    func updateCameraDimension( dimension: SIMD2<Float> ) {
        aspect = dimension.x / dimension.y
    }

    var projectionMatrix: float4x4 {
        return float4x4( fov: fov, aspect: aspect, near: near, far: far )
    }

    var viewMatrixLHS: float4x4 {

        var toLHS = float4x4.identity()
        toLHS.columns.2.z = -1.0

        return toLHS
    }
}


