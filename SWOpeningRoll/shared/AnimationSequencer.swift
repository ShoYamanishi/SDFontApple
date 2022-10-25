import Foundation

class AnimationSequencer {

    var timeStart       : TimeInterval

    let temporalPoints  : [TimeInterval]
    let spacialPoints   : [SIMD3<Float>]
    let colors          : [SIMD4<Float>]

    var timeNow         : TimeInterval
    var spacialPointNow : SIMD3<Float>
    var colorNow        : SIMD4<Float>
    var animationActive : Bool

    init(
        temporalPoints  : [TimeInterval],
        spacialPoints   : [SIMD3<Float>],
        colors          : [SIMD4<Float>]
    ) {
        self.timeStart       = Date().timeIntervalSince1970
        self.temporalPoints  = temporalPoints
        self.spacialPoints   = spacialPoints
        self.colors          = colors
        self.timeNow         = timeStart
        self.spacialPointNow = spacialPoints[0]
        self.colorNow        = colors[0]
        self.animationActive = false
    }

    func startAnimation() {
        timeStart = Date().timeIntervalSince1970
        timeNow         = timeStart
        spacialPointNow = spacialPoints[0]
        colorNow        = colors[0]
        animationActive = true
    }

    func step() {

        let timeNow = Date().timeIntervalSince1970
        let timeSinceStart = timeNow - timeStart

        for i in 1 ..< temporalPoints.count {

            if temporalPoints[i] > timeSinceStart {

                // interpolate between temporalPoints[i-1] and  temporalPoints[i]

                let alpha = Float(   (  timeSinceStart     - temporalPoints[ i - 1 ] )
                                   / ( temporalPoints[ i ] - temporalPoints[ i - 1 ] ) )

                spacialPointNow = spacialPoints[ i - 1 ] * ( 1.0 - alpha ) + spacialPoints[i] * alpha
                colorNow        = colors[ i - 1 ]        * ( 1.0 - alpha ) + colors[i]        * alpha
                return
            }
        }
        animationActive = false
        spacialPointNow = spacialPoints[ temporalPoints.count - 1 ]
        colorNow        = colors       [ temporalPoints.count - 1 ]
    }
}
