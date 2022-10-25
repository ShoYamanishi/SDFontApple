import MetalKit

class SDFontSignedDistanceGenerator : MetalComputeBase {

    struct Config {

        var drawAreaSideLen : Int32
        var spreadThickness : Int32
        var width           : Int32
        var height          : Int32

        init( drawAreaSideLen : Int32, spreadThickness : Int32 ) {
            self.drawAreaSideLen = drawAreaSideLen
            self.spreadThickness = spreadThickness
            self.width           = 0
            self.height          = 0
        }
    }
    
    var config               : Config
    var signedDistanceBuffer : MTLBuffer!

    init( device : MTLDevice, drawAreaSideLen : Int , spreadThickness : CGFloat ) {

        self.signedDistanceBuffer = device.makeBuffer(
            length:  drawAreaSideLen * drawAreaSideLen * MemoryLayout<Float>.stride,
            options: .storageModeShared
        )

        config = Config( drawAreaSideLen : Int32(drawAreaSideLen), spreadThickness : Int32(ceil(spreadThickness) ) )

        super.init( device : device )

        createPipelineState( functionName : "generate_signed_distance" )
    }

    func generate( pixmapBuffer: MTLBuffer, glyphBounds : SignedDistanceFontGlyphBounds ) {

        config.width  = Int32( glyphBounds.outer.size.width  )
        config.height = Int32( glyphBounds.outer.size.height )

        guard let commandBuffer = queue!.makeCommandBuffer() else {
            print ("ERROR: Cannot make command buffer for SigneDistanceGenerator.")
            return
        }

        let encoder = commandBuffer.makeComputeCommandEncoder()

        encoder!.setComputePipelineState( pipelineState! )

        encoder!.setBytes( &config, length: MemoryLayout<Config>.stride, index: 0 )
        encoder!.setBuffer( pixmapBuffer,         offset: 0, index: 1 )
        encoder!.setBuffer( signedDistanceBuffer, offset: 0, index: 2 )

        let threadConfig = MetalComputeBase.getThreadConfiguration( numThreads: Int( config.width * config.height ) )
        encoder!.dispatchThreadgroups(
                                   MTLSizeMake( threadConfig.numGroupsPerGrid,   1, 1 ),
            threadsPerThreadgroup: MTLSizeMake( threadConfig.numThreadsPerGroup, 1, 1 )
        )
        encoder!.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

