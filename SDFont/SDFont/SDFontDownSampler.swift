import MetalKit

class Downsampler : MetalComputeBase {

    struct Config {
    
        // per-glyph local upsampled region
        var sideLenSrc       : Int32
        var widthSrc         : Int32
        var heightSrc        : Int32

        // output drawing area
        var sideLenDst       : Int32
        var widthDst         : Int32
        var heightDst        : Int32
        var originXDst       : Int32
        var originYDst       : Int32

        var upSamplingFactor : Int32
        var spreadThickness  : Float
        var flipY            : Int32

        init( rowLenSrc : Int32, rowLenDst : Int32, upSamplingFactor: Int32, spreadThickness : Float , flipY: Bool ) {

            self.sideLenSrc       = rowLenSrc
            self.sideLenDst       = rowLenDst
            self.upSamplingFactor = upSamplingFactor
            self.spreadThickness  = spreadThickness

            self.widthSrc         = 0
            self.heightSrc        = 0
            self.widthDst         = 0
            self.heightDst        = 0
            self.originXDst       = 0
            self.originYDst       = 0
            self.flipY            = flipY ? 1 : 0
        }
    }

    var bufferSrc  : MTLBuffer
    var bufferDst  : MTLBuffer
    var config     : Config

    init(
        device           : MTLDevice,
        bufferSrc        : MTLBuffer,
        bufferSrcSideLen : Int,
        bufferDst        : MTLBuffer,
        bufferDstSideLen : Int,
        upSamplingFactor : Int,
        spreadThickness  : Float,
        flipY            : Bool
    ) {
        self.bufferSrc = bufferSrc
        self.bufferDst = bufferDst

        config = Config(
            rowLenSrc        : Int32(bufferSrcSideLen),
            rowLenDst        : Int32(bufferDstSideLen),
            upSamplingFactor : Int32(upSamplingFactor),
            spreadThickness  : spreadThickness,
            flipY            : flipY
        )

        super.init( device : device )

        createPipelineState( functionName : "downsample")
    }

    func perform(
        originalBounds           : SignedDistanceFontGlyphBounds,
        upSampledLocalizedBounds : SignedDistanceFontGlyphBounds
    ) {

        config.widthSrc   = Int32( upSampledLocalizedBounds.outer.size.width  )
        config.heightSrc  = Int32( upSampledLocalizedBounds.outer.size.height )
        config.widthDst   = Int32( originalBounds.outer.size.width  )
        config.heightDst  = Int32( originalBounds.outer.size.height )
        config.originXDst = Int32( originalBounds.outer.origin.x )
        config.originYDst = Int32( originalBounds.outer.origin.y )

        guard let commandBuffer = queue!.makeCommandBuffer() else {
            print ("ERROR: Cannot make command buffer for Downsampler.")
            return
        }

        let encoder = commandBuffer.makeComputeCommandEncoder()

        encoder!.setComputePipelineState( pipelineState! )

        encoder!.setBytes(  &config, length: MemoryLayout<Config>.stride, index: 0 )
        encoder!.setBuffer( bufferSrc,  offset: 0, index: 1 )
        encoder!.setBuffer( bufferDst,  offset: 0, index: 2 )

        let threadConfig = MetalComputeBase.getThreadConfiguration( numThreads: Int( config.widthDst * config.heightDst ) )
        encoder!.dispatchThreadgroups(
                                   MTLSizeMake( threadConfig.numGroupsPerGrid,   1, 1 ),
            threadsPerThreadgroup: MTLSizeMake( threadConfig.numThreadsPerGroup, 1, 1 )
        )
        encoder!.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
