import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {

    @EnvironmentObject var worldManager: WorldManager

    func makeCoordinator() -> Coordinator {

        Coordinator(self)
    }

    func makeNSView( context: NSViewRepresentableContext<MetalView> ) -> MTKView {

        let mtkView = MTKView()

        mtkView.delegate                 = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.device                   = worldManager.device
        mtkView.framebufferOnly          = false
        mtkView.clearColor               = MTLClearColor( red: 0, green: 0, blue: 0, alpha: 0 )
        mtkView.drawableSize             = mtkView.frame.size
        //mtkView.enableSetNeedsDisplay    = true
        mtkView.depthStencilPixelFormat  = .depth32Float

        context.coordinator.renderCoordinator.createPipelineStates( colorPixelFormat: mtkView.colorPixelFormat )
        context.coordinator.mtkView( mtkView, drawableSizeWillChange: mtkView.bounds.size )

        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView> ) {

    }

    class Coordinator : NSObject, MTKViewDelegate {

        let renderCoordinator : RenderCoordinator
        let parent            : MetalView

        init( _ parent: MetalView ) {

            self.renderCoordinator = RenderCoordinator( worldManager : parent.worldManager, device: parent.worldManager.device )
            self.parent            = parent

            super.init()
        }

        func mtkView( _ view : MTKView, drawableSizeWillChange size: CGSize ) {

            renderCoordinator.mtkView( view, drawableSizeWillChange: size )
        }

        func draw( in view: MTKView ) {

            renderCoordinator.draw( in: view )
        }
    }
}
