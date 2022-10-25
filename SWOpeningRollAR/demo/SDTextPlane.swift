import Foundation
import MetalKit
import SDFont

class SDTextPlane {

    static let TextureMargin : CGFloat = 0.001 // margin from the real glyph box to include the spread part

    let device              : MTLDevice
    var dimension           : CGSize
    var sdHelper            : SDFontRuntimeHelper
    var scaleForTypeSetting : CGFloat

    var vertexBuffer        : MTLBuffer?
    var numVertices         : Int
    var indexBuffer         : MTLBuffer?
    var numIndices          : Int

    var localTransform      : float4x4
    var globalTransform     : float4x4
    var uniformPerInstance  : UniformPerInstance
    var perInstanceBuffer   : MTLBuffer?
    
    var uniformSDFont       : UniformSDFont
    var sdFontUniformBuffer : MTLBuffer?

    var sdFontTexture       : MTLTexture?

    var animationSequencer  : AnimationSequencer?

    init(
        device              : MTLDevice,
        dimension           : CGSize,
        sdHelper            : SDFontRuntimeHelper,
        scaleForTypeSetting : CGFloat,
        uniformSDFont       : UniformSDFont
    ) {
        self.device              = device
        self.dimension           = dimension
        self.sdHelper            = sdHelper
        self.scaleForTypeSetting = scaleForTypeSetting

        self.numVertices         = 0
        self.numIndices          = 0
        self.localTransform      = float4x4.identity()
        self.globalTransform     = float4x4.identity()
        self.uniformPerInstance  = UniformPerInstance( modelMatrix  : self.globalTransform * self.localTransform )
        self.uniformSDFont       = uniformSDFont

        self.perInstanceBuffer   = UniformPerInstance.generateMTLBuffer( device : device, instances : [uniformPerInstance] )
        self.sdFontUniformBuffer = UniformSDFont.generateMTLBuffer( device : device, v : &self.uniformSDFont )

        self.sdFontTexture       = sdHelper.texture()
    }

    func setLocalTransform( translation : SIMD3<Float> ) {

        localTransform.columns.3.x = translation.x
        localTransform.columns.3.y = translation.y
        localTransform.columns.3.z = translation.z
        self.uniformPerInstance  = UniformPerInstance( modelMatrix  : self.globalTransform * self.localTransform )
        UniformPerInstance.updateMTLBuffer( buffer : perInstanceBuffer!, instances : [uniformPerInstance] )
    }

    func setGlobalTransform( transform : float4x4 ) {

        self.globalTransform = transform
        self.uniformPerInstance  = UniformPerInstance( modelMatrix  : self.globalTransform * self.localTransform )
        UniformPerInstance.updateMTLBuffer( buffer : perInstanceBuffer!, instances : [uniformPerInstance] )
    }

    func rotate90AroundX() {

        localTransform.columns.0 = SIMD4<Float>( 1.0,  0.0,  0.0,  0.0 )
        localTransform.columns.1 = SIMD4<Float>( 0.0,  0.0, -1.0,  0.0 )
        localTransform.columns.2 = SIMD4<Float>( 0.0,  1.0,  0.0,  0.0 )
        self.uniformPerInstance  = UniformPerInstance( modelMatrix  : self.globalTransform * self.localTransform )
        UniformPerInstance.updateMTLBuffer( buffer : perInstanceBuffer!, instances : [uniformPerInstance] )
    }

    func setAnimation(
        temporalPoints  : [TimeInterval],
        spacialPoints   : [SIMD3<Float>],
        colors          : [SIMD4<Float>]
    ) {
        animationSequencer = AnimationSequencer(
            temporalPoints  : temporalPoints,
            spacialPoints   : spacialPoints,
            colors          : colors
        )
    }

    func startAnimation() {
        animationSequencer!.startAnimation()
    }

    func animationActive()-> Bool {
        animationSequencer!.animationActive
    }

    func step() {

        animationSequencer!.step()

        let s = animationSequencer!.spacialPointNow
        setLocalTransform( translation : s )
        uniformSDFont.foregroundColor = animationSequencer!.colorNow
        UniformSDFont.updateMTLBuffer( buffer : sdFontUniformBuffer!, v : &uniformSDFont )
    }

    func setText( textPlain: String, lineAlignment: CTTextAlignment ) {
        let rectForTypeSetting = CGRect(
            x      : -0.5 * dimension.width  * scaleForTypeSetting,
            y      : -0.5 * dimension.height * scaleForTypeSetting,
            width  :        dimension.width  * scaleForTypeSetting,
            height :        dimension.height * scaleForTypeSetting
        )
        let scaledBounds = sdHelper.typeset( frameRect: rectForTypeSetting, textPlain: textPlain, lineAlignment: lineAlignment )

        generateVerticesAndIndices( bounds : scaledBounds )
    }

    func generateVerticesAndIndices( bounds : [SDFontRuntimeHelper.GlyphBound] )
    {
        var indexBegin : Int32 = 0

        var positions  : [ SIMD4<Float> ] = []
        var uvs        : [ SIMD2<Float> ] = []
        var indices    : [ Int32        ] = []

        for bound in bounds {
            var factor : CGFloat
            if bound.textureBound.size.width > bound.textureBound.size.height {
               factor = bound.frameBound.size.width / bound.textureBound.size.width
            }
            else {
                factor = bound.frameBound.size.height / bound.textureBound.size.height
            }
            let frameMargin   = factor * Self.TextureMargin

            let xLeft  = Float( ( bound.frameBound.origin.x                                - frameMargin ) / scaleForTypeSetting )
            let xRight = Float( ( bound.frameBound.origin.x + bound.frameBound.size.width  + frameMargin ) / scaleForTypeSetting )
            let yLower = Float( ( bound.frameBound.origin.y                                - frameMargin ) / scaleForTypeSetting )
            let yUpper = Float( ( bound.frameBound.origin.y + bound.frameBound.size.height + frameMargin ) / scaleForTypeSetting )

            positions.append( SIMD4<Float>( xLeft,  yLower, 0.0, 1.0 ) )
            positions.append( SIMD4<Float>( xRight, yLower, 0.0, 1.0 ) )
            positions.append( SIMD4<Float>( xRight, yUpper, 0.0, 1.0 ) )
            positions.append( SIMD4<Float>( xLeft,  yUpper, 0.0, 1.0 ) )

            let uLeft  = Float( bound.textureBound.origin.x - Self.TextureMargin )
            let uRight = Float( bound.textureBound.origin.x + bound.textureBound.size.width + Self.TextureMargin )
            let vLower = Float( bound.textureBound.origin.y - Self.TextureMargin )
            let vUpper = Float( bound.textureBound.origin.y + bound.textureBound.size.height + Self.TextureMargin )

            uvs.append( SIMD2<Float>( uLeft,  vLower ) )
            uvs.append( SIMD2<Float>( uRight, vLower ) )
            uvs.append( SIMD2<Float>( uRight, vUpper ) )
            uvs.append( SIMD2<Float>( uLeft,  vUpper ) )

            indices.append( indexBegin     )
            indices.append( indexBegin + 1 )
            indices.append( indexBegin + 2 )
            indices.append( indexBegin     )
            indices.append( indexBegin + 2 )
            indices.append( indexBegin + 3 )

            indexBegin += 4
        }

        vertexBuffer = VertexInPositionUV.generateMTLBuffer(
            device    : device,
            positions : positions,
            uvs       : uvs
        )

        numVertices = positions.count
        numIndices  = indices.count
        indexBuffer = VertexInIndex.generateMTLBuffer( device: device, indices : indices )
    }
}
