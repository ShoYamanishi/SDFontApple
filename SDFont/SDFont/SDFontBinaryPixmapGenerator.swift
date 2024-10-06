import MetalKit

class SDFontBinaryPixmapGenerator {

    static let EPSILON = 1.0e-8
    let fontName        : CFString
    let fontSize        : CGFloat
    var cgFont          : CGFont?
    let drawAreaSideLen : Int
    let flipY           : Bool

    var pixelBuffer     : MTLBuffer!
    var context         : CGContext!

    init( device: MTLDevice, fontName: CFString, fontSize : CGFloat, drawAreaSideLen : Int, flipY : Bool ) {

        self.fontName        = fontName
        self.fontSize        = fontSize
        self.cgFont          = CGFont( fontName )

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

        var g = forGlyph

        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
        context.fill( CGRect( x: 0, y: 0, width: CGFloat( drawAreaSideLen ), height: CGFloat( drawAreaSideLen ) ) )
        context.setFillColor( red: 1, green: 1, blue: 1, alpha: 1 )

        var bboxes   = UnsafeMutablePointer<CGRect>.allocate( capacity: 1 )
        var advances = UnsafeMutablePointer<Int32>.allocate( capacity: 1 )

        if ( !cgFont!.getGlyphBBoxes( glyphs: [g], count: 1, bboxes: bboxes ) ) {
            print ( "WARNING: Cant't retrieve BBox for glyph [\(g)].")
            return
        }
        if ( !cgFont!.getGlyphAdvances(glyphs: [g], count: 1, advances: advances ) ) {
            print ( "WARNING: Cant't retrieve advances for glyph [\(g)].")
            return
        }

        let fontScaleFactor = fontSize / CGFloat( cgFont!.unitsPerEm )

        let rect = CGRect(
            origin: CGPoint( x: bboxes[0].origin.x * fontScaleFactor, y: bboxes[0].origin.y * fontScaleFactor ),
            size: CGSize( width:  bboxes[0].width * fontScaleFactor, height: bboxes[0].height * fontScaleFactor )
        )

        let normalizedAdvance = CGFloat( advances[0] ) / CGFloat( cgFont!.unitsPerEm )

        if    abs( glyphBounds.inner.size.width  - rect.size.width  ) >= Self.EPSILON
           || abs( glyphBounds.inner.size.height - rect.size.height ) >= Self.EPSILON  {

            print ( "WARNING: Boundary requested: \(glyphBounds.inner.size) is different from the boundary from CGFont: \(rect.size) for glyph [\(g)]")
        }

        var translation = CGAffineTransform( translationX: glyphBounds.inner.origin.x - rect.origin.x,
                                                        y: glyphBounds.inner.origin.y - rect.origin.y  )
        context.textMatrix = translation
        context.setFont( cgFont! )
        context.setFontSize( fontSize )
        context.showGlyphs( [g], at: [CGPoint( x: 0, y: 0 )] )
    }
}

