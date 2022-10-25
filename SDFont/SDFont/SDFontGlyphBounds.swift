import CoreGraphics

struct SignedDistanceFontGlyphBounds {

    let outer           : CGRect  // with spread. Integer-aligned
    let inner           : CGRect  // glyph bounds from CoreText
    let spreadThickness : CGFloat // spread in pixels
    let textureSideLen  : CGFloat // length of the dies of the texture in which this glyph resides.

    func normalizedInnerBound( flipY: Bool ) -> CGRect {

        let adjustedOriginY = flipY ? (textureSideLen - (inner.origin.y + inner.size.height)) : inner.origin.y

        return CGRect(
            x      : inner.origin.x    / textureSideLen,
            y      : adjustedOriginY   / textureSideLen,
            width  : inner.size.width  / textureSideLen,
            height : inner.size.height / textureSideLen
        )
    }

    init( outerOrigin : CGPoint, outerSize : CGSize, spreadThickness : CGFloat, innerSize : CGSize, textureSideLen : CGFloat ) {

        self.outer = CGRect(

            x      : outerOrigin.x,
            y      : outerOrigin.y,
            width  : outerSize.width,
            height : outerSize.height
        )

        self.inner = CGRect(

            x      : outerOrigin.x + spreadThickness,
            y      : outerOrigin.y + spreadThickness,
            width  : innerSize.width,
            height : innerSize.height
        )

        self.spreadThickness = spreadThickness
        self.textureSideLen  = textureSideLen
    }

    func localizeAndUpSample( upSamplingFactor : CGFloat ) -> Self {

        let converted = SignedDistanceFontGlyphBounds(

            outerOrigin     : CGPoint(x: 0, y: 0 ),

            outerSize       : CGSize( width:  self.outer.size.width  * upSamplingFactor,
                                      height: self.outer.size.height * upSamplingFactor ),

            spreadThickness : self.spreadThickness * upSamplingFactor,

            innerSize       : CGSize( width:  self.inner.size.width  * upSamplingFactor,
                                      height: self.inner.size.height * upSamplingFactor ),

            textureSideLen  : self.textureSideLen * upSamplingFactor
        )

        return converted
    }
}
