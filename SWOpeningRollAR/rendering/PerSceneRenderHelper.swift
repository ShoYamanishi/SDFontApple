import Foundation
import MetalKit

class PerSceneRenderHelper {

    static let FragmentFunctionNameSDFont         = "fragment_sdfont"
    static let VertexFunctionNamePositionUV       = "vertex_position_uv"

    static let SamplerStateMaxAnisotropy          = 4

    static let VertexBufferIndexVertexIn          = 0
    static let VertexBufferIndexUniformPerScene   = 1
    static let VertexBufferIndexUniformPerInstance = 2

    static let FragmentBufferIndexUniformPerScene = 1
    static let FragmentBufferIndexUniformSDFont   = 4

    static let TextureIndexSDFont                 = 3

    let device                : MTLDevice
    var pipelineState         : MTLRenderPipelineState?
    var depthStencilState     : MTLDepthStencilState?
    let bufferUniformPerScene : MTLBuffer?
    var samplerState          : MTLSamplerState?

    init(
        device                : MTLDevice,
        bufferUniformPerScene : MTLBuffer
    ) {
        self.device                 = device
        self.bufferUniformPerScene  = bufferUniformPerScene
        self.samplerState           = Self.buildSamplerStateSDFont( device: device )

        let desc = MTLDepthStencilDescriptor()
        desc.depthCompareFunction = .always
        desc.isDepthWriteEnabled = false
        depthStencilState = device.makeDepthStencilState( descriptor: desc )
    }


    func createPipelineState( colorPixelFormat : MTLPixelFormat ) {
    
        let library = device.makeDefaultLibrary()

        let descriptor = MTLRenderPipelineDescriptor()

        descriptor.vertexFunction   = library!.makeFunction( name: Self.VertexFunctionNamePositionUV )
        descriptor.fragmentFunction = library!.makeFunction( name: Self.FragmentFunctionNameSDFont   )

        descriptor.vertexDescriptor                = MTLVertexDescriptor.positionUV()
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        descriptor.colorAttachments[0].isBlendingEnabled           = true
        descriptor.colorAttachments[0].rgbBlendOperation           = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor        = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor   = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].alphaBlendOperation         = .add;
        descriptor.colorAttachments[0].sourceAlphaBlendFactor      = .sourceAlpha;
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;

        descriptor.depthAttachmentPixelFormat  = .depth32Float

        do {
            pipelineState = try device.makeRenderPipelineState( descriptor: descriptor )
        } catch let error {
            fatalError( error.localizedDescription )
        }
    }

    func renderModelSDFont(
        encoder                  : MTLRenderCommandEncoder,
        bufferVertexIn           : MTLBuffer,
        bufferUniformPerInstance : MTLBuffer,
        numInstances             : Int,
        bufferIndices            : MTLBuffer,
        numIndices               : Int,
        bufferUniformSDFont      : MTLBuffer,
        textureSDFont            : MTLTexture,
        wireFrame                : Bool = false
    ) {
        encoder.setRenderPipelineState( pipelineState! )
        encoder.setDepthStencilState( depthStencilState )

        encoder.setVertexBuffer( bufferVertexIn,           offset: 0, index: Self.VertexBufferIndexVertexIn           )
        encoder.setVertexBuffer( bufferUniformPerScene,    offset: 0, index: Self.VertexBufferIndexUniformPerScene    )
        encoder.setVertexBuffer( bufferUniformPerInstance, offset: 0, index: Self.VertexBufferIndexUniformPerInstance )

        encoder.setFragmentBuffer( bufferUniformSDFont,   offset: 0, index: Self.FragmentBufferIndexUniformSDFont   )

        encoder.setFragmentTexture( textureSDFont, index: Self.TextureIndexSDFont )

        encoder.setFragmentSamplerState( samplerState, index: 0 )

        if wireFrame {
            encoder.setTriangleFillMode( .lines )
        }

        encoder.drawIndexedPrimitives(
            type:              .triangle,
            indexCount:        numIndices,
            indexType:         .uint32,
            indexBuffer:       bufferIndices,
            indexBufferOffset: 0,
            instanceCount:     numInstances,
            baseVertex:        0,
            baseInstance:      0
        )

        if wireFrame {
            encoder.setTriangleFillMode( .fill )
        }
    }

    static func buildSamplerStateSDFont( device: MTLDevice ) -> MTLSamplerState? {

        let descriptor = MTLSamplerDescriptor()
        descriptor.mipFilter    = .linear
        descriptor.minFilter    = .nearest;
        descriptor.magFilter    = .linear;
        descriptor.sAddressMode = .clampToZero;
        descriptor.tAddressMode = .clampToZero;
        descriptor.maxAnisotropy = Self.SamplerStateMaxAnisotropy

        let samplerState = device.makeSamplerState( descriptor: descriptor )
        
        return samplerState
    }
}
