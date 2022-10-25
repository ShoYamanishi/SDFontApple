import MetalKit

class SDFontBinaryPixmapGenerator {

    static let EPSILON = 1.0e-8
    let fontName        : CFString
    let fontSize        : CGFloat
    let font            : CTFont
    let drawAreaSideLen : Int
    let flipY           : Bool

    var pixelBuffer     : MTLBuffer!
    var context         : CGContext!

    init( device: MTLDevice, fontName: CFString, fontSize : CGFloat, drawAreaSideLen : Int, flipY : Bool ) {

        self.fontName        = fontName
        self.fontSize        = fontSize
        self.font            = CTFontCreateWithName( fontName, fontSize, nil )
        self.drawAreaSideLen = drawAreaSideLen
        self.flipY           = flipY

        guard let pixelBuffer = device.makeBuffer( length: MemoryLayout<UInt8>.stride * drawAreaSideLen * drawAreaSideLen, options: .storageModeShared )
        else {
            print ( "ERROR: MTLBuffer cannot be made for the Pixmap of size \(drawAreaSideLen)" )
            return
        }
        self.pixelBuffer = pixelBuffer

        let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceGray();
        let bitmapInfo = CGBitmapInfo( rawValue:   CGImageAlphaInfo.none.rawValue
                                                 | CGImageByteOrderInfo.orderDefault.rawValue
                                                 | CGImagePixelFormatInfo.packed.rawValue
                                     )

        guard let context = CGContext(
            data:             pixelBuffer.contents(),
            width:            drawAreaSideLen,
            height:           drawAreaSideLen,
            bitsPerComponent: 8,
            bytesPerRow:      drawAreaSideLen,
            space:            colorSpace,
            bitmapInfo:       bitmapInfo.rawValue
        ) else {
            print ( "ERROR: CGContext cannot be made for the Pixmap of size \(drawAreaSideLen)" )
            return
        }
        context.setAllowsAntialiasing(false)
        self.context = context

        if flipY {
            self.context.translateBy( x: 0, y: CGFloat(drawAreaSideLen) )
            self.context.scaleBy( x: 1, y: -1 )
        }
    }

    func generatePixmap( forGlyph : CGGlyph, fontSize : CGFloat, glyphBounds : SignedDistanceFontGlyphBounds ) {

        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        context.fill( CGRect( x: 0, y: 0, width: CGFloat( drawAreaSideLen ), height: CGFloat( drawAreaSideLen ) ) )
        context.setFillColor( red: 1, green: 1, blue: 1, alpha: 1 )

        var rect = CGRect()
        var g    = forGlyph
        CTFontGetBoundingRectsForGlyphs( font, .horizontal, &g, &rect, 1 )

        if    abs( glyphBounds.inner.size.width  - rect.size.width  ) >= Self.EPSILON
           || abs( glyphBounds.inner.size.height - rect.size.height ) >= Self.EPSILON  {

            print ( "WARNING: Boundary requested: \(glyphBounds.inner.size) is different from the boundary from CTFont: \(rect.size) for glyph [\(g)]")
        }

        var translation = CGAffineTransform( translationX: glyphBounds.inner.origin.x - rect.origin.x,
                                                        y: glyphBounds.inner.origin.y - rect.origin.y  )

        guard let path = CTFontCreatePathForGlyph( font, g, &translation ) else {

            print ( "WARNING: Font path cannot be generated for glyph [\(g)]. Maybe an empty glyph")
            return
        }

        context.addPath( path )
        context.fillPath()
    }
}

