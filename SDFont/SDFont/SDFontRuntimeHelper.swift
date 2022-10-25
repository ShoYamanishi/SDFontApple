import MetalKit


/// SDFontRuntimerHelper performs the type-setting for the signed distance fonts.
/// At the initialization, it takes a signed distance font in MTLTexture and its accompanying list of bounding boxes.
/// It then takes the text and the drawing area as the inputs, performs typesetting with CoreText, and generates
/// the necessary data in a list of pairs of bounding boxes in order to render the text with Metal.
/// The first part of the pair specifies the rectagular region in the drawing area, and the second specifies the
/// bounding box in the signed distance font texture.
/// Please note that the list of the bounding boxes does not have a 1-to-1 mapping to the character sequence of the input text, as
/// the glyphs can contain ligatures, such as "ff" and "fi".
public class SDFontRuntimeHelper {


    /// The output from typeset() in the list of pairs of rectangular bounds.
    public struct GlyphBound {

        /// The rectangular bounding box in the specified drawing area.
        public let frameBound   : CGRect

        /// The rectangular bounding box of the glyph in the texture coodinate space.
        public let textureBound : CGRect
    }
    let verbose                 : Bool
    let device                  : MTLDevice
    var fontName                : String
    var font                    : CTFont?
    var signedDistanceBuffer    : MTLTexture?
    var textureBounds           : [ CGRect ]?

    var contextBuffer           : [ UInt8 ]
    let context                 : CGContext

    /// Use this initializer, if the font is generated at runtime with SDFontGenerator.
    /// - Parameters:
    ///   - generator: SDFont generator
    ///   - fontSize: The size of the font used for type setting.
    public init( generator: SDFontGenerator, fontSize : Int, verbose : Bool ) {
        self.verbose              = verbose
        self.device               = generator.device
        self.fontName             = generator.fontName
        self.font                 = CTFontCreateWithName( fontName as CFString, CGFloat(fontSize), nil )
        self.signedDistanceBuffer = generator.generateMTLTexture()
        self.textureBounds        = generator.textureBounds
        self.contextBuffer        = [ 0 ]
        
        // the following context is used as a dummy parameter to CTRunGetImageBounds().
        let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceGray();
        let bitmapInfo = CGBitmapInfo( rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue | CGImagePixelFormatInfo.packed.rawValue )
        self.context              = CGContext(
            data:             &contextBuffer,
            width:            1,
            height:           1,
            bitsPerComponent: 8,
            bytesPerRow:      1,
            space:            colorSpace,
            bitmapInfo:       bitmapInfo.rawValue
        )!
    }

    /// - Parameters:
    ///   - device: The metal device
    ///   - fontName: The name of the font used. This must be the same one used for the generation of the signed distance font.
    ///   - fontSize: The size of the font used for type setting.
    ///   - fileName: The file name without extension for the PNG and JSON files to be loaded.
    ///   - path: The subdirectory of the path in which the JSON file is stored.
    /// Use this if the signed distance fonts were generated off-line and stored in the PNG/JSON file pair.
    public init( device: MTLDevice, fontName: String, fontSize: Int, fileName : String, path : String?, usePosixPath : Bool, verbose : Bool ) {
        self.verbose              = verbose
        self.device   = device
        self.fontName = fontName
        self.font                 = CTFontCreateWithName( fontName as CFString, CGFloat(fontSize), nil )
        self.signedDistanceBuffer = SDFontIOHandler.loadTextureFromPNGFile(
            device       : device,
            fileName     : fileName,
            path         : path,
            usePosixPath : usePosixPath,
            verbose      : verbose
        )
        self.textureBounds = SDFontIOHandler.loadMetricsFromJSONFile(
            fileName     : fileName,
            path         : path,
            usePosixPath : usePosixPath,
            verbose      : verbose
        )

        self.contextBuffer = [ 0 ]
        
        // the following context is used as a dummy parameter to CTRunGetImageBounds().
        let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceGray();
        let bitmapInfo = CGBitmapInfo( rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue | CGImagePixelFormatInfo.packed.rawValue )
        self.context              = CGContext(
            data:             &contextBuffer,
            width:            1,
            height:           1,
            bitsPerComponent: 8,
            bytesPerRow:      1,
            space:            colorSpace,
            bitmapInfo:       bitmapInfo.rawValue
        )!
    }

    /// - Returns: The metal texture of type MTLPixelFormatR8Unorm that contains the signed distance values.
    public func texture() -> MTLTexture {
        return signedDistanceBuffer!
    }

    /// Performs type setting and generates the data in a list of bounding boxes for the given text to render it with a Metal shader.
    /// - Parameters:
    ///   - frameRect: The drawing area to which the text is rendered.
    ///   - textPlain: The plain text to be type-set and drawn to the drawing area.
    ///   - lineAlignment: .left, .center, or .right
    /// - Returns: List of pairs of bounding boxes. The first bounding box of each pair specifies the rectangular resion in the drawing area to which the glyph is drawn. The second bounding box specifies the region in the texture.
    public func typeset( frameRect: CGRect, textPlain: String, lineAlignment : CTTextAlignment ) -> [GlyphBound] {

        var alignment : CTTextAlignment = lineAlignment
        var settings : CTParagraphStyleSetting?
        withUnsafePointer( to: &alignment) { (ptr: UnsafePointer<CTTextAlignment>) in
            settings = CTParagraphStyleSetting(
                spec      : .alignment,
                valueSize : MemoryLayout<CTTextAlignment>.size,
                value     : ptr
            )
        }
        let paragraphStyle = CTParagraphStyleCreate([ settings! ], 1)

        let attr        = [ kCTFontAttributeName           : font!,
                            kCTParagraphStyleAttributeName : paragraphStyle
                          ] as CFDictionary
        let textAttr    = CFAttributedStringCreate( nil, textPlain as CFString, attr )
        let textRange   = CFRange( location: 0, length: CFAttributedStringGetLength( textAttr ) );
        let framePath   = CGPath(rect: frameRect, transform: nil )
        let frameSetter = CTFramesetterCreateWithAttributedString( textAttr! )
        let ctFrame     = CTFramesetterCreateFrame( frameSetter,  textRange, framePath, nil )

        let frameBoundingRect = framePath.boundingBoxOfPath;
        let ctLines = CTFrameGetLines( ctFrame ) as [AnyObject] as! [CTLine]
        var ctLineOrigins = [CGPoint]( repeating: CGPoint( x:0, y:0 ), count: ctLines.count )
        CTFrameGetLineOrigins( ctFrame, CFRangeMake(0,0), &ctLineOrigins )

        var outArray : [GlyphBound] = []

        for i in 0 ..< ctLines.count {

            let ctLine       = ctLines[i]
            let ctLineOrigin = ctLineOrigins[i]
            let ctRuns = CTLineGetGlyphRuns( ctLine ) as [AnyObject] as! [CTRun]

            for ctRun in ctRuns {

                let glyphCount = CTRunGetGlyphCount( ctRun )

                var glyphs = [CGGlyph]( repeating: CGGlyph(), count: glyphCount )
                CTRunGetGlyphs( ctRun, CFRangeMake(0,0), &glyphs )

//                var runOrigins = [CGPoint]( repeating: CGPointMake(0,0), count: glyphCount )
//                CTRunGetPositions( ctRun, CFRangeMake(0,0), &runOrigins )

                for j in 0 ..< glyphCount {

//                    let runOrigin = runOrigins[j]

                    let glyph     = glyphs[j]
                    let glyphBound = CTRunGetImageBounds( ctRun, context, CFRangeMake(j, 1));

                    let frameBound = CGRect(
                        x      : frameBoundingRect.origin.x + ctLineOrigin.x + glyphBound.origin.x,
                        y      : frameBoundingRect.origin.y + ctLineOrigin.y + glyphBound.origin.y,
                        width  : glyphBound.size.width,
                        height : glyphBound.size.height
                    )
                    let textureBound = textureBounds![ Int(glyph) ]
                    outArray.append( GlyphBound( frameBound: frameBound, textureBound: textureBound ) )
                }
            }
        }

        return outArray
    }
    
    /// - Returns: The list of font names available in the system.
    ///
    /// Please consult https://developer.apple.com/fonts/ for the official information.
    public static func listAvailableFonts() -> [String] {
#if os(iOS)
        var fontList : [String] = []
        for family in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: family) {
                fontList.append( fontName )
            }
        }
        return fontList
#else
       return NSFontManager.shared.availableFonts
#endif
    }
}
