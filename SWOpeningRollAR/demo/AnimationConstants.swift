import MetalKit

class AnimationConstants {

    static let Helvetica     = "Helvetica"
    static let HelveticaBold = "Helvetica-Bold"
    static let SDTextureSize = 1024

    // MARK: Text 1

    static let Text1          = "A long time ago, in a gallaxy far\nfar away...."
    static let FontName1      = Helvetica
    static let ColorOn1       = SIMD4<Float>(0.2, 0.6, 1.0, 1.0)
    static let ColorOff1      = SIMD4<Float>(0.2, 0.6, 1.0, 0.0)
    static let Dimension1     = CGSize( width: 1.2, height: 0.24 )
    static let Scale1         = 250.0
    static let Translation1   = SIMD3<Float>( x: 0.065, y: -0.1, z: -0.15 )
    static let Translation1Demo = SIMD3<Float>( x: 0.065, y: 0.03, z: -0.15 )

    static let TemporalPoints1  : [TimeInterval] = [ 0.0,          1.0,          2.0,          4.0,          5.0          ]
    static let SpacialPoints1   : [SIMD3<Float>] = [ Translation1, Translation1, Translation1, Translation1, Translation1 ]
    static let Colors1          : [SIMD4<Float>] = [ ColorOff1,    ColorOff1,    ColorOn1,     ColorOn1,     ColorOff1    ]

    static var SDFontUniform1 = UniformSDFont(
        foregroundColor : ColorOn1,
        funcType        : UniformSDFont.FunctionType.SDFONT_SMOOTH_STEP,
        point1          : 0.2,
        point2          : 0.9,
        width           : 0.0
    )

    // MARK: Text 2

    static let Text2          = "STAR\nWARS"
    static let FontName2      = HelveticaBold
    static let ColorOn2       = SIMD4<Float>( 1.0, 0.8, 0.0, 1.0 )
    static let ColorOff2      = SIMD4<Float>( 1.0, 0.8, 0.0, 0.0 )
    static let Dimension2     = CGSize( width: 2.0, height: 1.2 )
    static let Scale2         = 25.0
    static let Translation2_1 = SIMD3<Float>( x: 0.0, y: 0.0, z:   0.0 )
    static let Translation2_2 = SIMD3<Float>( x: 0.0, y: 0.0, z: -10.0 )
    static let Translation2_3 = SIMD3<Float>( x: 0.0, y: 0.0, z: -15.0 )
    static let Translation2Demo = SIMD3<Float>( x: 0.0, y: 0.0, z: -1.5 )

    static let TemporalPoints2  : [TimeInterval] = [ 0.0,            5.99,           6.0,            14.0,           17.0,          ]
    static let SpacialPoints2   : [SIMD3<Float>] = [ Translation2_1, Translation2_1, Translation2_1, Translation2_2, Translation2_3 ]
    static let Colors2          : [SIMD4<Float>] = [ ColorOff2,      ColorOff2,      ColorOn2,       ColorOn2,       ColorOff2      ]

    static var SDFontUniform2 = UniformSDFont(
        foregroundColor : ColorOn2,
        funcType        : UniformSDFont.FunctionType.SDFONT_TRAPEZOID,
        point1          : 0.55,
        point2          : 0.65,
        width           : 0.1
    )

    // MARK: Text 3
    
    static let Text3 =
"""
EPISODE IV

It is a period of civil war.
Rebel spaceships, striking
from a hidden base, have won
their first victory against
the evil Galactic Empire.

During the battle, Rebel
spies managed to steal secret
plans to the Empire's
ultimate weapon, the DEATH
STAR, an armored space
station with enough power
to destroy an entire planet.

Pursued by the Empire's
sinister agents, Princess
Leia races home aboard her
starship, custodian of the
stolen plans that can save her
people and restore
freedom to the galaxy....
"""
    static let FontName3      = Helvetica
    static let ColorOn3       = SIMD4<Float>( 1.0, 0.8, 0.0, 1.0 )
    static let ColorOff3      = SIMD4<Float>( 1.0, 0.8, 0.0, 0.0 )
    static let Dimension3     = CGSize( width: 0.6, height: 1.0 )
    static let Scale3         = 500.0
    static let Translation3_1 = SIMD3<Float>( x: 0.0, y: -0.06, z:   0.6 )
    static let Translation3_2 = SIMD3<Float>( x: 0.0, y: -0.06, z:  -0.5 + 0.6 )
    static let Translation3_3 = SIMD3<Float>( x: 0.0, y: -0.06, z:  -0.5 - 0.25 + 0.6 )
    static let Translation3Demo = SIMD3<Float>( x: 0.0, y: -0.06, z:  0.1 )

    static let TemporalPoints3  : [TimeInterval] = [ 0.0,            7.99,           8.0,            18.0,           23.0,          ]
    static let SpacialPoints3   : [SIMD3<Float>] = [ Translation3_1, Translation3_1, Translation3_1, Translation3_2, Translation3_3 ]
    static let Colors3          : [SIMD4<Float>] = [ ColorOff3,      ColorOff3,      ColorOn3,       ColorOn3,       ColorOff3      ]

    static var SDFontUniform3 = UniformSDFont(
        foregroundColor : ColorOn3,
        funcType        : UniformSDFont.FunctionType.SDFONT_STEP,
        point1          : 0.49,
        point2          : 0.51,
        width           : 0.1
    )
}
