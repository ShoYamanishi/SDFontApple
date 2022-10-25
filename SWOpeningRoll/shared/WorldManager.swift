import Foundation
import MetalKit
import SwiftUI
import SDFont


class WorldManager : ObservableObject {

    var      device:                 MTLDevice!
    var      colorPixelFormat:       MTLPixelFormat

    var      camera:                 Camera

    var      scene:                  UniformPerScene
    var      sceneBuffer:            MTLBuffer?

    var      sdHelperHelveticaBold:  SDFontRuntimeHelper?
    var      sdHelperHelvetica:      SDFontRuntimeHelper?

    var      textPlaneHelper:        PerSceneRenderHelper?

    var      textPlane1:             SDTextPlane?
    var      textPlane2:             SDTextPlane?
    var      textPlane3:             SDTextPlane?

    public init( device : MTLDevice ) {

        self.device           = device
        self.colorPixelFormat = .invalid
        self.camera           = Camera()
        self.scene            = UniformPerScene()
        self.sceneBuffer      = UniformPerScene.generateMTLBuffer( device: device, uniformPerScene: &scene )

        // Set this to false after running the App for the first time.
        let generatingSDFonts : Bool = true

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

        print ("Available fonts in the system: ")
        for fontName in SDFontRuntimeHelper.listAvailableFonts() {
            print ("    [\(fontName)]")
        }

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

        textPlane1!.startAnimation()
        textPlane2!.startAnimation()
        textPlane3!.startAnimation()
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

    func createPipelineStates( colorPixelFormat: MTLPixelFormat ) {

        self.colorPixelFormat = colorPixelFormat
        self.textPlaneHelper?.createPipelineState( colorPixelFormat: colorPixelFormat )
    }

    func updateScreenSizes(_ view: MTKView ){
        camera.updateCameraDimension( dimension: SIMD2<Float>(x: Float(view.frame.size.width), y: Float(view.frame.size.height) ) )
        scene.update( camera: camera )
        UniformPerScene.updateMTLBuffer(buffer: sceneBuffer!, uniformPerScene: &scene )
    }

    func updateWorld() {

        scene.update( camera: camera )
        UniformPerScene.updateMTLBuffer(buffer: sceneBuffer!, uniformPerScene: &scene )
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

    func encode( encoder : MTLRenderCommandEncoder ) {

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
    }
}
