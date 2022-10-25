import MetalKit

class ZeroInitializer : MetalComputeBase {

    struct Config {
        var lengthInInt32: Int32
    }

    override init( device : MTLDevice ) {
        super.init( device : device )
        createPipelineState( functionName : "initialize_with_zero")
    }

    func perform( buffer: MTLBuffer, lengthInInt32 : Int ) {

        var config = Config( lengthInInt32 : Int32(lengthInInt32) )

        guard let commandBuffer = queue!.makeCommandBuffer() else {
            print ("ERROR: Cannot make command buffer for ZeroInitializer.")
            return
        }

        let encoder = commandBuffer.makeComputeCommandEncoder()

        encoder!.setComputePipelineState( pipelineState! )

        encoder!.setBytes( &config, length: MemoryLayout<Config>.stride, index: 0 )
        encoder!.setBuffer( buffer,  offset: 0, index: 1 )

        encoder!.dispatchThreadgroups(
                                   MTLSizeMake( 1,                    1, 1 ),
            threadsPerThreadgroup: MTLSizeMake( Self.ThreadsPerGroup, 1, 1 )
        )
        encoder!.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}

