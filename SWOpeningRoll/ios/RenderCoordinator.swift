import Foundation
import MetalKit


class RenderCoordinator: NSObject, MTKViewDelegate {

    var device:            MTLDevice!
    var commandQueue:      MTLCommandQueue!
    var colorPixelFormat:  MTLPixelFormat!
    var worldManager:      WorldManager?

    var previousFrameSize: CGSize // to detect screen dimension change. SwiftUI does not always call mtkView().

    init( worldManager: WorldManager, device : MTLDevice ) {

        self.worldManager = worldManager
        self.device = worldManager.device
        guard
            let commandQueue = device.makeCommandQueue()
        else {
            fatalError("GPU not available")
        }
        self.commandQueue = commandQueue

        self.previousFrameSize = CGSize( width: 0.0, height: 0.0 )

        super.init()

    }

    /// 2nd part of init. It must wait until device and the pixel format become available in MTKView
    func createPipelineStates( colorPixelFormat: MTLPixelFormat ) {
        worldManager?.createPipelineStates( colorPixelFormat: colorPixelFormat )
    }
    
        // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize ) {

        self.colorPixelFormat = view.colorPixelFormat
        worldManager?.updateScreenSizes( view )
    }

    func draw( in view: MTKView ) {

        if previousFrameSize != view.frame.size  {
            previousFrameSize  = view.frame.size
            self.mtkView( view, drawableSizeWillChange: view.frame.size )
        }

        worldManager?.updateWorld()

        guard
            let descriptor    = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder( descriptor: descriptor )
        else {
            return
        }

        worldManager?.encode( encoder: encoder )

        encoder.endEncoding()

        guard let drawable = view.currentDrawable
        else {
            return
        }
        commandBuffer.present( drawable )
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
