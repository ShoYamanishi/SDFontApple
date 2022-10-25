import Foundation
import MetalKit
import SwiftUI
import SDFont


class WorldManager : ObservableObject, TouchMTKViewDelegate {

    var      device:                 MTLDevice!
    var      colorPixelFormat:       MTLPixelFormat
    var      arCoordinator:          ARCoordinator?
    var      screenSize:             CGSize

    var      pipelineState:          MTLRenderPipelineState!
    var      depthState:             MTLDepthStencilState!

    var      camera:                 Camera
    var      cameraTransform:        float4x4

    var      scene:                  UniformPerScene
    var      sceneBuffer:            MTLBuffer?

    var      sdHelperHelveticaBold:  SDFontRuntimeHelper?
    var      sdHelperHelvetica:      SDFontRuntimeHelper?

    var      textPlaneHelper:        PerSceneRenderHelper?

    var      textPlane1:             SDTextPlane?
    var      textPlane2:             SDTextPlane?
    var      textPlane3:             SDTextPlane?

    var      animationStarted:       Bool

    public init( device : MTLDevice ) {

        self.device           = device
        self.colorPixelFormat = .invalid
        self.screenSize       = CGSize( width: 0.0, height: 0.0 )
        self.cameraTransform  = matrix_identity_float4x4
        self.camera           = Camera()
        self.scene            = UniformPerScene()
        self.sceneBuffer      = UniformPerScene.generateMTLBuffer( device: device, uniformPerScene: &scene )
        self.animationStarted = false
        // Set this to false after running the App for the first time.
        let generatingSDFonts : Bool = false

        if generatingSDFonts {
            generateSDFonts( fontName : AnimationConstants.Helvetica,     textureSize: AnimationConstants.SDTextureSize )
            generateSDFonts( fontName : AnimationConstants.HelveticaBold, textureSize: AnimationConstants.SDTextureSize )
        }

        sdHelperHelveticaBold = SDFontRuntimeHelper(
            device       : device,
            fontName     : AnimationConstants.HelveticaBold,
            fontSize     : 12,
            fileName     : AnimationConstants.HelveticaBold,
            path         : nil,
            usePosixPath : false,
            verbose      : true
        )

        sdHelperHelvetica = SDFontRuntimeHelper(
            device       : device,
            fontName     : AnimationConstants.Helvetica,
            fontSize     : 12,
            fileName     : AnimationConstants.Helvetica,
            path         : nil,
            usePosixPath : false,
            verbose      : true
        )

        self.textPlaneHelper = PerSceneRenderHelper(
            device                : device,
            bufferUniformPerScene : self.sceneBuffer!
        )

        // MARK: - Text 1 "Long time ago..."

        self.textPlane1 = SDTextPlane(
            device              : device,
            dimension           : AnimationConstants.Dimension1,
            sdHelper            : sdHelperHelvetica!,
            scaleForTypeSetting : AnimationConstants.Scale1,
            uniformSDFont       : AnimationConstants.SDFontUniform1
        )
        self.textPlane1!.setText( textPlain: AnimationConstants.Text1, lineAlignment: .left )

        self.textPlane1!.setAnimation(
            temporalPoints  : AnimationConstants.TemporalPoints1,
            spacialPoints   : AnimationConstants.SpacialPoints1,
            colors          : AnimationConstants.Colors1
        )

        // MARK: - Text 2 "STAR WARS"

        self.textPlane2 = SDTextPlane(
            device              : device,
            dimension           : AnimationConstants.Dimension2,
            sdHelper            : sdHelperHelveticaBold!,
            scaleForTypeSetting : AnimationConstants.Scale2,
            uniformSDFont       : AnimationConstants.SDFontUniform2
        )
        self.textPlane2!.setText( textPlain: AnimationConstants.Text2, lineAlignment: .center )

        self.textPlane2!.setAnimation(
            temporalPoints  : AnimationConstants.TemporalPoints2,
            spacialPoints   : AnimationConstants.SpacialPoints2,
            colors          : AnimationConstants.Colors2
        )

        // MARK: - Text 3 Main Text

        self.textPlane3 = SDTextPlane(
            device              : device,
            dimension           : AnimationConstants.Dimension3,
            sdHelper            : sdHelperHelvetica!,
            scaleForTypeSetting : AnimationConstants.Scale3,
            uniformSDFont       : AnimationConstants.SDFontUniform3
        )
        self.textPlane3!.setText( textPlain: AnimationConstants.Text3, lineAlignment: .center )
        self.textPlane3!.rotate90AroundX()

        self.textPlane3!.setAnimation(
            temporalPoints  : AnimationConstants.TemporalPoints3,
            spacialPoints   : AnimationConstants.SpacialPoints3,
            colors          : AnimationConstants.Colors3
        )
     }

    func generateSDFonts( fontName : String, textureSize: Int) {

        let sdGeneratorHelvetica = SDFontGenerator(
            device                             : device,
            fontName                           : fontName,
            outputTextureSideLen               : textureSize,
            spreadFactor                       : 0.2,
            upSamplingFactor                   : 4,
            glyphNumCutoff                     : 512,
            verbose                            : true,
            usePosixPath                       : false
        )

        if !sdGeneratorHelvetica.writeToPNGFile(fileName: fontName, path: nil ) {
            print ("ERROR: cannot write PNG file for \(fontName).")
        }

        if !sdGeneratorHelvetica.writeMetricsToJSONFile(fileName: fontName, path: nil ) {
            print ("ERROR: cannot write PNG file for \(fontName).")
        }
    }

    func createPipelineStates( mtkView: MTKView ) {

        self.colorPixelFormat = mtkView.colorPixelFormat
        self.textPlaneHelper?.createPipelineState( colorPixelFormat: colorPixelFormat )
    }

    func updateScreenSizes( size: CGSize ) {
        screenSize = size
    }

    func updateViewAndProjectionMatrixForCamera( viewMatrix: float4x4, projectionMatrix: float4x4, transform: float4x4 ) {

        // MARK: - Coordinate conversion
        // Flip the Z axis to convert geometry from right handed to left handed
        // ARKit uses the right-hand coordinate system, while Metal uses the left-hand coordinate system.
        var coordinateSpaceTransform = matrix_identity_float4x4
        coordinateSpaceTransform.columns.2.z = -1.0


        camera.viewMatrixLHS    = viewMatrix * coordinateSpaceTransform
        camera.projectionMatrix = projectionMatrix

        var transformNoOrientation = float4x4.identity()
        transformNoOrientation.columns.3 = transform.columns.3
        self.cameraTransform = coordinateSpaceTransform * transformNoOrientation
        
    }

    func updateWorld() {

        scene.update( camera: camera )
        UniformPerScene.updateMTLBuffer(buffer: sceneBuffer!, uniformPerScene: &scene )
        
        if animationStarted {

            textPlane1!.step()
            textPlane2!.step()
            textPlane3!.step()

            if     !( textPlane1!.animationActive())
                && !( textPlane2!.animationActive() )
                && !( textPlane3!.animationActive() ) {

                textPlane1!.startAnimation()
                textPlane2!.startAnimation()
                textPlane3!.startAnimation()
            }
        }
    }

    func draw( in view: MTKView, commandBuffer: MTLCommandBuffer ) {

        if animationStarted {

            let descriptor = view.currentRenderPassDescriptor

            // At this point, the image from the camera has been drawn to the drawable, and we should not clear it.
            let oldAction = descriptor!.colorAttachments[0].loadAction
            descriptor!.colorAttachments[0].loadAction = .load

            guard
                let encoder = commandBuffer.makeRenderCommandEncoder( descriptor: descriptor! )
            else {
                return
            }

            textPlaneHelper?.renderModelSDFont(
                encoder                  : encoder,
                bufferVertexIn           : textPlane1!.vertexBuffer!,
                bufferUniformPerInstance : textPlane1!.perInstanceBuffer!,
                numInstances             : 1,
                bufferIndices            : textPlane1!.indexBuffer!,
                numIndices               : textPlane1!.numIndices,
                bufferUniformSDFont      : textPlane1!.sdFontUniformBuffer!,
                textureSDFont            : textPlane1!.sdFontTexture!,
                wireFrame                : false
            )

            textPlaneHelper?.renderModelSDFont(
                encoder                  : encoder,
                bufferVertexIn           : textPlane2!.vertexBuffer!,
                bufferUniformPerInstance : textPlane2!.perInstanceBuffer!,
                numInstances             : 1,
                bufferIndices            : textPlane2!.indexBuffer!,
                numIndices               : textPlane2!.numIndices,
                bufferUniformSDFont      : textPlane2!.sdFontUniformBuffer!,
                textureSDFont            : textPlane2!.sdFontTexture!,
                wireFrame                : false
            )

            textPlaneHelper?.renderModelSDFont(
                encoder                  : encoder,
                bufferVertexIn           : textPlane3!.vertexBuffer!,
                bufferUniformPerInstance : textPlane3!.perInstanceBuffer!,
                numInstances             : 1,
                bufferIndices            : textPlane3!.indexBuffer!,
                numIndices               : textPlane3!.numIndices,
                bufferUniformSDFont      : textPlane3!.sdFontUniformBuffer!,
                textureSDFont            : textPlane3!.sdFontTexture!,
                wireFrame                : false
            )
            
            encoder.endEncoding()

            descriptor!.colorAttachments[0].loadAction = oldAction
        }
    }
    
    func touchesBegan( location: CGPoint, size: CGRect ) {

        if !animationStarted {

            textPlane1!.setGlobalTransform( transform: cameraTransform )
            textPlane2!.setGlobalTransform( transform: cameraTransform )
            textPlane3!.setGlobalTransform( transform: cameraTransform )

            textPlane1!.startAnimation()
            textPlane2!.startAnimation()
            textPlane3!.startAnimation()

            animationStarted = true
        }
    }

    func touchesMoved( location: CGPoint, size: CGRect ) {}
    
    func touchesEnded( location: CGPoint, size: CGRect ) {}
}
