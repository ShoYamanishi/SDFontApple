import Foundation

import simd

class Camera {
 
    var projectionMatrix: float4x4
    var viewMatrixLHS:    float4x4

    init () {
        self.projectionMatrix = float4x4.identity()
        self.viewMatrixLHS    = float4x4.identity()
    }

    init ( projectionMatrix: float4x4, viewMatrixLHS: float4x4 ) {
        self.projectionMatrix = projectionMatrix
        self.viewMatrixLHS    = viewMatrixLHS
    }
}


