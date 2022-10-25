import MetalKit

class MetalComputeBase {

#if os(iOS)
    static let ThreadsPerGroup = 512
#else
    static let ThreadsPerGroup = 1024
#endif

    let device        : MTLDevice
    var queue         : MTLCommandQueue?
    var pipelineState : MTLComputePipelineState?

    init( device : MTLDevice ) {

        self.device        = device
        self.queue         = nil
        self.pipelineState = nil

        guard let queue = device.makeCommandQueue()
        else {
            print ("ERROR: Cannot make a Metal command queue.")
            return
        }
        self.queue = queue
    }

    func createPipelineState( functionName : String) {

        do {
            let library = try device.makeLibrary(source: SDFontMetalSourceCode, options: nil)

            let desc = MTLComputePipelineDescriptor()
            desc.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
            desc.computeFunction = library.makeFunction( name: functionName )
            do {
                pipelineState = try device.makeComputePipelineState( descriptor: desc, options: [], reflection : nil )
            }
            catch {
                print ( "ERROR: Cannot make pipeline state for \(functionName)" )
                return
            }
        } catch {
            fatalError("ERROR: Cannot compile metal code from the baked string.")
        }
    }

    static func getThreadConfiguration( numThreads: Int ) -> ( numGroupsPerGrid: Int, numThreadsPerGroup: Int ) {

        let TPG = Self.ThreadsPerGroup

        let numThreadsAligned32 = Int( ( ( numThreads + 31 ) / 32 ) * 32 )
        let numThreadsPerGroup  = Int( ( numThreadsAligned32 < TPG ) ? numThreadsAligned32 : TPG )
        let numGroupsPerGrid    = Int( ( numThreadsAligned32 + TPG - 1 ) / TPG )

        return ( numGroupsPerGrid: numGroupsPerGrid, numThreadsPerGroup: numThreadsPerGroup )
    }
}

