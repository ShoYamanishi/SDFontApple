import MetalKit

/// SDFontGenerator takes a font name, and generates a MTLTexture and a list of bounding boxes.
/// The texture contains the glyphs in the quantized uint8 format, and the list of bounding boxes
/// specifies the location and the size of each glyph in the texture.
/// The MTLTexture can be stored in a PNG file, and the list of the bounding boxes can be
/// stored in a JSON file as part of the off-line processing.
/// It does not produce font metrics, such as bearings and kerning, as we can rely on
/// CoreText's type-setter at runtime.
///
/// How it works internally:
///
/// Main inputs:
///
/// - The font name
///
/// - The size of the square output texture in pixels
///
/// Process:
///
/// 1. Fix a font size temporarily and find the size of the bounding boxes of the glyphs of the fonts.
///
/// 2. Find a good rectangular shape as close to the square as possible,
///    in which all the bounding boxes (including the margin for the spreads) can be accommodated.
///
/// 3. Scale the rectangular shape, and the corresponding font size to fit the glyphs to the given texture size.
///
/// At this point, we have the following:
///
/// - The font size
///
/// - The rectangular drawing area close to the output square texture dimension
///
/// - For each glyph, the location of its bounding box in the drawing area
///
/// For each glyph, find the signed distance values and store them to the location in the output drawing area.
///   For that we increase the font size by multiplying it by an up-sampling factor.
///
///    4.1. Draw the glyph in the increased font size to a binary bitmap region with CoreGraphics and CoreText.
///
///    4.2. Find the signed distance values for each pixel by a Metal shader.
///
///    4.3. Down-sample and normalize the signed distance values and store them in the output drawing area by a Metal shader.
///
/// Outputs: MTLTexture and the list of bounding boxes.
///
/// - MTLTexture that contains the signed distance of the glyphs packed in it.
///
/// - List of bounding boxes of the glyphs in the texture coordinate space
///
/// NOTE: Libfreetype is also considered but declined due to the following reasons.
/// 1. Difficulty of using it on iOS.
/// 2. The font files stored in a system directory are inaccessible by the user Apps on iOS.
/// 3. CoreText provides good type-setting functionalities.

public class SDFontGenerator {

    // user inputs
    let device                             : MTLDevice
    let fontName                           : String
    let spreadFactor                       : Double
    let outputTextureSideLen               : Int
    let upSamplingFactor                   : Int
    let glyphNumCutoff                     : Int
    let verbose                            : Bool
    let usePosixPath                       : Bool

    // internal
    var upSampledPerGlyphTextureSideLen    : Int
    var upSampledFontSize                  : CGFloat

    // outputs
    var signedDistanceBuffer               : MTLBuffer?
    var signedDistanceTexture              : MTLTexture?
    var textureBounds                      : [ CGRect ]

    /// - Parameters:
    ///   - device: The metal device
    ///   - fontName: Name of the font in post-script name if possible, or any other name that CoreText can recognize.
    ///   - outputTextureSideLen: The length in pixels of the sides of the square-shape texture, e.g., 4096.
    ///   - spreadFactor: It determines the maximum distance in pixels considered when generating the signed distance. It is the fraction of the average length of the sides (width and height) of the glyphs. Usually 0.2 is appropriate.
    ///   - upSamplingFactor: Used to generate the signed distance values more accurately. Usually 4 is appropriate.
    ///   - glyphNumCutoff: The upper limit on the glyph index. 0 means no limit. It can be used to reduce the texture size for some conditions. Usually a font has more than 1,000 glyphs, but most common glyphs for the English leters are allocated below 256. If glyphNumCutoff is set to 256, the glyphs, whose indices are above 255, are not considered. Use this with caution, as the type setter of CoreText uses combined ligature glyphs such as "ff" and "fi"whose indices are above 256.
    ///   - verbose: Set to true to generate INFO to the console.
    ///   - usePosixPath: Set to true if SDFont is used for a command-line App.
    ///   An ordinary Swift App seems to have to run in a confined environment called Container. If the Sandboxing is turned on, the App is allowed to access
    ///     certain directories such as Photos/ under the user's own directory, which are symbolic-linked into the Container.
    ///   A command-line Swift App seems to have no such restrictions, and can access in the usual Unix/Posix manner. The variable usePosixPath is to absorb those differences.
    ///
    /// NOTE: on usePosixPath and the actual file paths:
    ///
    ///   - Command-line Swift App for macos, usePosixPath = true:
    ///
    ///   The call to `writeMetricsToJSONFile()` and `writeMetricsToPNGFile()` handle the file path as follows:
    ///
    ///           var documentsURL = URL( fileURLWithPath: (path != nil) ? path! : "./" )
    ///
    ///   - GUI Swift App for macos,usePosixPath to false:
    ///
    ///   The call to `writeMetricsToJSONFile()` and `writeMetricsToPNGFile()` handle the file path as follows:
    ///
    ///           var documentsURL = URL( fileURLWithPath: FileManager.default.currentDirectoryPath )
    ///           if let path = path {
    ///               documentsURL = documentsURL.appendingPathComponent( path )
    ///           }
    ///
    ///   - GUI Swift App for iOS, usePosixPath is ignored:
    ///
    ///   The call to `writeMetricsToJSONFile()` and `writeMetricsToPNGFile()` handle the file path as follows:
    ///
    ///           var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    ///           if let path = path {
    ///               documentsURL = documentsURL.appendingPathComponent( path )
    ///           }
    ///
    /// Please turn on verbose and check the console output to see the actual absolute file paths determined by FileManager.


    public init(
        device                             : MTLDevice,
        fontName                           : String,
        outputTextureSideLen               : Int,
        spreadFactor                       : Double,
        upSamplingFactor                   : Int,
        glyphNumCutoff                     : Int,
        verbose                            : Bool,
        usePosixPath                       : Bool
    ) {
        self.device = device

        self.fontName = fontName

        self.spreadFactor = clamp( low: 1.0, val: spreadFactor, high: 2.0 )

        if outputTextureSideLen % 16 != 0 {
            print ( "WARNING: outputTextureSideLen not aligned to 16. Rounding up." )
        }
        self.outputTextureSideLen = roundUp16( outputTextureSideLen )

        self.upSamplingFactor = clamp( low: 1, val: upSamplingFactor, high: 100 )

        if glyphNumCutoff <= 0 {
            self.glyphNumCutoff = Int.max
        }
        else {
            self.glyphNumCutoff = glyphNumCutoff
        }
        self.verbose      = verbose
        self.usePosixPath = usePosixPath

        self.upSampledPerGlyphTextureSideLen = 0
        self.upSampledFontSize               = 0.0

        self.signedDistanceBuffer    = nil
        self.signedDistanceTexture   = nil
        self.textureBounds           = []

        guard let signedDistanceBuffer = device.makeBuffer(
            length  : MemoryLayout<UInt8>.stride * outputTextureSideLen * outputTextureSideLen,
            options : .storageModeShared
        ) else {
            print ("ERROR: Output MTLBuffer cannot be allocated." )
            return
        }
        var zeroInitializer : ZeroInitializer? = ZeroInitializer( device : device )
        zeroInitializer!.perform(
            buffer        : signedDistanceBuffer,
            lengthInInt32 : MemoryLayout<UInt8>.stride * outputTextureSideLen * outputTextureSideLen / MemoryLayout<Int32>.stride
        )
        zeroInitializer = nil
        
        self.signedDistanceBuffer = signedDistanceBuffer

        let packingFinder = SDFontGlyphPackingFinder(
            fontName        : fontName as CFString,
            spreadFactor    : spreadFactor,
            drawAreaSideLen : outputTextureSideLen,
            glyphNumCutoff  : self.glyphNumCutoff,
            verbose         : verbose
        )
        self.upSampledPerGlyphTextureSideLen = roundUp16( upSamplingFactor * Int(packingFinder.maxOuterGlyphBoundsSideLen + 1.0) )
        self.upSampledFontSize = CGFloat(upSamplingFactor) * packingFinder.referenceFontSize

        if verbose {
            print ( "INFO: Reference Font size: [\(packingFinder.referenceFontSize)]." )
            print ( "INFO: Spread in pixels: [\(packingFinder.spreadThickness)]" )
            print ( "INFO: Occupancy Rate: [\(packingFinder.occupancyRate)]" )
            print ( "INFO: Up-sampled per-glyph texture side length: [\(self.upSampledPerGlyphTextureSideLen)]" )
            print ( "INFO: Up-sampled font size: [\(self.upSampledFontSize)]" )
        }

        let pixmapGenerator = SDFontBinaryPixmapGenerator(
            device          : device,
            fontName        : fontName as CFString,
            fontSize        : self.upSampledFontSize,
            drawAreaSideLen : self.upSampledPerGlyphTextureSideLen,
            flipY           : true
        )

        let signedDistanceGenerator = SDFontSignedDistanceGenerator(
            device          : device,
            drawAreaSideLen : self.upSampledPerGlyphTextureSideLen,
            spreadThickness : packingFinder.spreadThickness * CGFloat(upSamplingFactor)
        )

        let downsampler = Downsampler(
            device           : device,
            bufferSrc        : signedDistanceGenerator.signedDistanceBuffer,
            bufferSrcSideLen : self.upSampledPerGlyphTextureSideLen,
            bufferDst        : signedDistanceBuffer,
            bufferDstSideLen : outputTextureSideLen,
            upSamplingFactor : upSamplingFactor,
            spreadThickness  : Float(packingFinder.spreadThickness),
            flipY            : true
        )

        let timeBegin = Date().timeIntervalSince1970
        var timeIntermediate1 = timeBegin

        for i in 0 ..< packingFinder.numGlyphs {

            let glyphBounds = packingFinder.glyphBoundsArray[i]

            if glyphBounds.inner.size.width  != 0.0 && glyphBounds.inner.size.height != 0.0 {

                let glyph = CGGlyph(i)

                let upSampledAndLocalizedGlyphBounds = glyphBounds.localizeAndUpSample( upSamplingFactor: CGFloat(upSamplingFactor) )
                pixmapGenerator.generatePixmap(
                    forGlyph   : glyph,
                    fontSize   : self.upSampledFontSize,
                    glyphBounds: upSampledAndLocalizedGlyphBounds
                )

                signedDistanceGenerator.generate( pixmapBuffer: pixmapGenerator.pixelBuffer, glyphBounds : upSampledAndLocalizedGlyphBounds )

                downsampler.perform( originalBounds : glyphBounds, upSampledLocalizedBounds : upSampledAndLocalizedGlyphBounds )
            }
            else {
                if verbose {
                    print ( "INFO: Bounding box for glyph \(i) is degenerate. Skipping." )
                }
            }
            self.textureBounds.append( glyphBounds.normalizedInnerBound( flipY : false ) )

            if verbose {
                let timeIntermediate2 = Date().timeIntervalSince1970
                if ( timeIntermediate2 - timeIntermediate1 > 10.0 ) {
                    timeIntermediate1 = timeIntermediate2
                    print ( "INFO: \(i) of \(packingFinder.numGlyphs) glyphs processed.")
                }
            }
        }

        if verbose {
            let timeEnd = Date().timeIntervalSince1970

            print ( "INFO: Total processing time: \(timeEnd - timeBegin) seconds. ")
        }

        // debugDrawBoundariesToOutput( bounds : packingFinder.glyphBoundsArray )
    }

    /// Generates the list of the bounding boxes of the glyphs in the texture coordinate system
    /// - Returns: The list of the bounding boxes of the glyphs arranged in the glyph index ordering.
    public func generateTextureBounds() -> [CGRect] {
        return textureBounds
    }

    /// Generates MTLTexture of the signed distance texture.
    /// - Returns: The metal texture of type MTLPixelFormatR8Unorm that contains the signed distance values.
    public func generateMTLTexture() -> MTLTexture? {
        if signedDistanceTexture == nil {
            signedDistanceTexture = SDFontIOHandler.generateMTLTexture( device : self.device, buf : signedDistanceBuffer!, sidesLenPixels : outputTextureSideLen )
            signedDistanceBuffer = nil // releasing MTLBuffer to save memory
        }
        return signedDistanceTexture
    }

    /// Writes the bounding boxes to the specified JSON file.
    /// - Parameters:
    ///   - fileName: File name without the extension.
    ///   - path: The file path in which the JSON file is stored. The interpretation of this depends on the OS and the initialization variable usePosixPath
    /// - Returns: True if successful
    public func writeMetricsToJSONFile( fileName : String, path : String? ) -> Bool {
        return SDFontIOHandler.writeMetricsToJSONFile( fileName : fileName, path : path, usePosixPath : usePosixPath, bounds : textureBounds, verbose : verbose )
    }

    /// Writes the texture to the specified PNG file
    /// This cannot be called, if generateMTLTexture() has been already called.
    /// - Parameters:
    ///   - fileName: File name without the extension.
    ///   - path: The file path in which the PNG file is stored. The interpretation of this depends on the OS and the initialization variable `usePosixPath`
    /// - Returns: True if successful
    public func writeToPNGFile( fileName : String, path : String? ) -> Bool {
        return SDFontIOHandler.writeToPNGFile(
            fileName       : fileName,
            path           : path,
            usePosixPath   : usePosixPath,
            buf            : signedDistanceBuffer!,
            sidesLenPixels : outputTextureSideLen,
            verbose        : verbose
        )
    }

#if os(iOS)
    /// Generates UIImage of the texture for visualizatin & debugging.
    /// This cannot be called, if generateMTLTexture() has been already called.
    /// - Returns: UIImage
    public func generateUIImage() -> UIImage? {
        return SDFontIOHandler.generateUIImage( buf : signedDistanceBuffer!, sidesLenPixels : outputTextureSideLen )
    }
#endif

    // MARK: - For debugging and visualization

    func debugDrawBoundariesToOutput( bounds : [SignedDistanceFontGlyphBounds] ) {

        let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceGray();
        let bitmapInfo = CGBitmapInfo( rawValue:   CGImageAlphaInfo.none.rawValue
                                                 | CGImageByteOrderInfo.orderDefault.rawValue
                                                 | CGImagePixelFormatInfo.packed.rawValue
                                     )
        guard let context = CGContext(
            data:             signedDistanceBuffer!.contents(),
            width:            outputTextureSideLen,
            height:           outputTextureSideLen,
            bitsPerComponent: 8,
            bytesPerRow:      outputTextureSideLen,
            space:            colorSpace,
            bitmapInfo:       bitmapInfo.rawValue
        ) else {
            print ( "ERROR: CGContext cannot be made for the Pixmap of size \(outputTextureSideLen)" )
            return
        }
        context.setAllowsAntialiasing(false)
        context.translateBy( x: 0, y: CGFloat(outputTextureSideLen) )
        context.scaleBy( x: 1, y: -1 )
        context.setStrokeColor(red: 1 , green: 1.0, blue: 1.0, alpha: 1)
        for bound in bounds {
            let b = bound.outer
            let p1 = CGPoint(x: b.origin.x,                y: b.origin.y)
            let p2 = CGPoint(x: b.origin.x + b.size.width, y: b.origin.y)
            let p3 = CGPoint(x: b.origin.x + b.size.width, y: b.origin.y + b.size.height)
            let p4 = CGPoint(x: b.origin.x,                y: b.origin.y + b.size.height)
            context.addLines(between: [ p1, p2, p3, p4, p1 ] )
        }

        for bound in bounds {
            let b = bound.inner
            let p1 = CGPoint(x: b.origin.x,                y: b.origin.y)
            let p2 = CGPoint(x: b.origin.x + b.size.width, y: b.origin.y)
            let p3 = CGPoint(x: b.origin.x + b.size.width, y: b.origin.y + b.size.height)
            let p4 = CGPoint(x: b.origin.x,                y: b.origin.y + b.size.height)
            context.addLines(between: [ p1, p2, p3, p4, p1 ] )

        }
        context.drawPath(using: .stroke )
    }
}

