import CoreGraphics
import CoreText

class SDFontGlyphPackingFinder {

    static let ALPHA                      : CGFloat = 0.1
    static let NUM_TRIALS_IMPROVEMENT     : Int     = 5
    static let MAX_NUM_TRIALS_IMPROVEMENT : Int     = 1000
    static let FONT_SIZE_FOR_PACKING      : CGFloat = 64.0
    static let FONT_SIZE_MINIMUM_ALLOWED  : CGFloat = 5.0

    let fontName                    : CFString
    let spreadFactor                : CGFloat
    let drawAreaSideLen             : Int
    let glyphNumCutoff              : Int
    let verbose                     : Bool
    var numGlyphs                   : Int
    var referenceFont               : CTFont?
    var spreadThickness             : CGFloat
    var referenceFontSize           : CGFloat
    var glyphBoundsArray            : [ SignedDistanceFontGlyphBounds ]
    var maxOuterGlyphBoundsSideLen  : CGFloat
    var meanInnerGlyphBoundsSideLen : CGFloat
    var occupancyRate               : CGFloat

    init( fontName: CFString, spreadFactor: CGFloat, drawAreaSideLen : Int, glyphNumCutoff : Int, verbose : Bool ) {

        self.fontName                    = fontName
        self.spreadFactor                = spreadFactor
        self.drawAreaSideLen             = drawAreaSideLen
        self.glyphNumCutoff              = glyphNumCutoff
        self.verbose                     = verbose
        self.numGlyphs                   = 0
        self.spreadThickness             = 0.0
        self.referenceFontSize           = 0.0
        self.glyphBoundsArray            = []
        self.maxOuterGlyphBoundsSideLen  = 0.0
        self.meanInnerGlyphBoundsSideLen = 0.0
        self.occupancyRate               = 0.0

        getFontAndCheckFontName( fontName )

        self.meanInnerGlyphBoundsSideLen = findMeanInnerSideLen()
        self.spreadThickness             = spreadFactor * meanInnerGlyphBoundsSideLen
        self.maxOuterGlyphBoundsSideLen  = findMaxOuterSideLen()

        let bestArea = findBestPackedArea()
        let suggestedFontSize = floor( Self.FONT_SIZE_FOR_PACKING * CGFloat( drawAreaSideLen ) / max( bestArea.width, bestArea.height ) )
        self.referenceFontSize = findBestFontSize( initialSize: suggestedFontSize )
        generateBoundingBoxes()

        var areaSum : CGFloat = 0.0

        for bound in glyphBoundsArray {

            areaSum += ( bound.outer.size.width * bound.outer.size.height )
        }
        self.occupancyRate = areaSum / ( CGFloat(self.drawAreaSideLen) * CGFloat(self.drawAreaSideLen) )

        referenceFont = nil
    }
    
    func findBestFontSize( initialSize : CGFloat ) -> CGFloat {

        var fontSize        = initialSize
        let allowedAreaSize = CGFloat(self.drawAreaSideLen)

        while fontSize >= Self.FONT_SIZE_MINIMUM_ALLOWED {
            self.referenceFont = CTFontCreateWithName( fontName, fontSize, nil )

            self.meanInnerGlyphBoundsSideLen = findMeanInnerSideLen()
            self.spreadThickness             = spreadFactor * self.meanInnerGlyphBoundsSideLen
            self.maxOuterGlyphBoundsSideLen  = findMaxOuterSideLen()

            let area = findPackedArea( widthLimit: allowedAreaSize, generateBoundingBoxes : false )

            if area.width <= allowedAreaSize &&  area.height <= allowedAreaSize {
                return fontSize
            }
            fontSize -= 1.0
        }

        print ( "WARNING: Glyphs can not be fully packed to the texture of size [\(self.drawAreaSideLen)] for the minimum font size [\(Self.FONT_SIZE_FOR_PACKING)]." )
        return fontSize
    }

    func getFontAndCheckFontName( _ fontName : CFString ) {

        let font = CTFontCreateWithName( fontName, Self.FONT_SIZE_FOR_PACKING, nil )
        let fontNameSelected = CTFontCopyFullName(font)

        let f1 = String( fontName ).replacingOccurrences( of: "-", with: "" )
        let f2 = String( fontNameSelected ).replacingOccurrences( of: " ", with: "" )

        if f1 != f2 {
            print ( "WARNING: Font selected [\(fontNameSelected)] is different from the requiested [\(fontName)].")
        }
        self.referenceFont = font
        self.referenceFontSize = Self.FONT_SIZE_FOR_PACKING
        let glyphCount = CTFontGetGlyphCount( font )

        self.numGlyphs = min( self.glyphNumCutoff, glyphCount )

        if verbose {
            print ("INFO: Number of glyphs in font \(fontName): [\(glyphCount)].")
            print ("INFO: Number of glyphs after cut-off: [\(numGlyphs)].")
        }
    }

    func findBestPackedArea() -> CGSize {

        let sqNumGlyphs = sqrt( Double(numGlyphs) )
        let initialAreaWidthLimit = ( self.meanInnerGlyphBoundsSideLen + spreadThickness * 2.0 ) * sqNumGlyphs
        var area = findPackedArea( widthLimit: initialAreaWidthLimit, generateBoundingBoxes : false )
        var bestArea = area
        var numTimesNotImproved = 0
        
        for _ in 0 ..< Self.MAX_NUM_TRIALS_IMPROVEMENT {
            
            if abs(bestArea.width - bestArea.height) <= abs(area.width - area.height) {

                numTimesNotImproved += 1

                if numTimesNotImproved >= Self.NUM_TRIALS_IMPROVEMENT {
                    return bestArea
                }
            }
            else {
                bestArea = area
            }
            let areaWidthLimit = area.width + (area.height - area.width) * Self.ALPHA
            area = findPackedArea( widthLimit: areaWidthLimit, generateBoundingBoxes : false )
        }

        print ( "WARNING: Feasible packing area for font [\(fontName)] can not be found. Using [\(bestArea)].")
        return bestArea
    }
    
    func findMeanInnerSideLen() -> CGFloat {

        var total : CGFloat = 0.0

        for i in 0 ..< self.numGlyphs {
            var g = CGGlyph(i)
            var rect = CGRect()
            CTFontGetBoundingRectsForGlyphs( self.referenceFont!,  .horizontal, &g, &rect, 1 )
            total += ( rect.width + rect.height )
        }

        return total / CGFloat( 2 * self.numGlyphs )
    }

    func findMaxOuterSideLen() -> CGFloat {

        var maxSideLen : CGFloat = 0.0

        for i in 0 ..< numGlyphs {
            var g = CGGlyph(i)
            var rect = CGRect()
            CTFontGetBoundingRectsForGlyphs( self.referenceFont!,  .horizontal, &g, &rect, 1 )
            maxSideLen = max( maxSideLen, rect.width, rect.height )
        }

        return maxSideLen + (self.spreadThickness * 2.0)
    }


    func generateBoundingBoxes() {

        let _ = findPackedArea( widthLimit: CGFloat(self.drawAreaSideLen), generateBoundingBoxes : true )
    }

    // pack the glyph left-to-right and then bottom-to-top in the area with the specified width.
    func findPackedArea( widthLimit: CGFloat, generateBoundingBoxes : Bool ) -> CGSize {
        
        var xAdvance            : CGFloat = 0.0
        var yAdvance            : CGFloat = 0.0
        var maxHeightCurrentRow : CGFloat = 0.0
        var maxWidth            : CGFloat = 0.0
        
        for i in 0 ..< self.numGlyphs {
            
            var g = CGGlyph(i)
            var rect = CGRect()
            CTFontGetBoundingRectsForGlyphs( self.referenceFont!, .horizontal, &g, &rect, 1 )
            
            // outer sizes rounded up to the integer
            let outerWidth  = ceil( rect.width  + ( spreadThickness * 2.0 ) )
            let outerHeight = ceil( rect.height + ( spreadThickness * 2.0 ) )

            if xAdvance + outerWidth > widthLimit {

                maxWidth = max( maxWidth, xAdvance )
                xAdvance = 0.0
                yAdvance += maxHeightCurrentRow
                maxHeightCurrentRow = outerHeight
            }
            else {
                maxHeightCurrentRow = max( maxHeightCurrentRow, outerHeight )
            }

            if generateBoundingBoxes {
                let bounds = SignedDistanceFontGlyphBounds(
                    outerOrigin     : CGPoint( x: xAdvance, y: yAdvance ),
                    outerSize       : CGSize( width: outerWidth, height: outerHeight ),
                    spreadThickness : spreadThickness,
                    innerSize       : rect.size,
                    textureSideLen  : CGFloat(self.drawAreaSideLen)
                )
                glyphBoundsArray.append( bounds )
            }

            xAdvance += outerWidth
            
        }
        if xAdvance > 0.0 {

            maxWidth = max( maxWidth, xAdvance )
            xAdvance = 0.0
            yAdvance += maxHeightCurrentRow
            maxHeightCurrentRow = 0.0
        }

        return CGSize( width: maxWidth, height: yAdvance + maxHeightCurrentRow )
    }
}
