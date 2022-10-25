import Foundation
import MetalKit
import UniformTypeIdentifiers
//import SDFont

var helpFound              : Bool   = false
var verboseFound           : Bool   = false
var showFontListFound      : Bool   = false
var fontName               : String = ""
var fontNameExpected       : Bool   = false
var glyphNumCutoff         : Int    = 0
var glyphNumCutoffExpected : Bool   = false
var spread                 : Double = 0
var spreadExpected         : Bool   = false
var upSample               : Int    =  1
var upSampleExpected       : Bool   = false
var outputPath             : String = ""
var outputPathExpected     : Bool   = false
var textureSize            : Int    = 512
var textureSizeExpected    : Bool   = false

for arg in CommandLine.arguments {

    switch arg {

      case "-h", "--help":
        helpFound = true

      case "-verbose":
        verboseFound = true

      case "-showfontlist":
        showFontListFound = true

      case "-fontname":
        fontNameExpected = true

      case "-glyphnumcutoff":
        glyphNumCutoffExpected = true

      case "-spread":
        spreadExpected = true

      case "-upsample":
        upSampleExpected = true

      case "-outputpath":
        outputPathExpected = true

      case "-texturesize":
        textureSizeExpected = true

      default:

        if fontNameExpected {
            fontName = arg
        }
        else if glyphNumCutoffExpected {
            if let intArg = Int(arg) {
                glyphNumCutoff = max(0, intArg)
            }
        }
        else if spreadExpected {
            if let doubleArg = Double(arg) {
                spread = min( 2.0, max(0.0, doubleArg) )
            }
        }
        else if upSampleExpected {
            if let intArg = Int(arg) {
                upSample = max(0, intArg)
            }
        }
        else if outputPathExpected {
            outputPath = arg
        }
        else if textureSizeExpected {
            if let intArg = Int(arg) {
                textureSize = max(0, intArg)
            }
        }

        fontNameExpected       = false
        glyphNumCutoffExpected = false
        spreadExpected         = false
        upSampleExpected       = false
        outputPathExpected     = false
        textureSizeExpected    = false
    }
}

if showFontListFound {
    print ("Available fonts:")
    print ("(Please consult https://developer.apple.com/fonts/ for the official information.)")
    for font in NSFontManager.shared.availableFonts {
        print ("    [\(font)]")
    }
    exit(0)
}

if helpFound || fontName == "" || spread == 0.0 || outputPath == "" {
    print ("")
    print ("sdfontgen : command-line signed distance font generator for macos.")
    print ("")
    print ("options")
    print ("")
    print ("    -h/--help: show this message" )
    print ("")
    print ("    -verbose: show INFO and WARNING messages" )
    print ("")
    print ("    -showfontlist: show the list of the fonts in the system" )
    print ("")
    print ("    -fontname <fontname>: name of the font, preferrably in Postscript name," )
    print ("        e.g. -fontname Helvetica" )
    print ("")
    print ("    -glyphnumcutoff <integer num>: maximum index of the glyphs to process." )
    print ("")
    print ("    -spread <real num>: specifies the margin around each glyph in the fraction" )
    print ("        of the average glyph width and height. Usually within the range of [0.1,0.2].")
    print ("")
    print ("    -upsample <integer num>: specifies the fontsize in the integer multiple to the original")
    print ("        font size, in order to sample the glyph bitmaps. The original fontsize")
    print ("        is determined as the best size to pack the glyphs to the output texture of")
    print ("        the specified size. For example if the side length of the output texture")
    print ("        is 2048, and the font is Helvecita with about 2000 glyphs, then the best")
    print ("        font size will be 43.0. If the upsample factor is 4, then the font size 172.0")
    print ("        is used to sample the glyph bitmap and to generate signed distance.")
    print ("        Usually within the range of [2,4].")
    print ("")
    print ("    -texturesize <integer num>: the length of the sides in pixels of the output texture.")
    print ("        Usually within the range of [512,4096].")
    print ("")
    print ("    -outputpath <path>: the path in which the output PNG and JSON files are stored.")
    print ("        If the outputpath is \"/path/to/output\", and fontname is \"Helvetica\",")
    print ("        then the output files will be /path/to/output/Helvetica.png and /path/to/output/Helvetica.json.")
    print ("")
    print ("NOTES on -glyphnumcutoff:")
    print ("  This is useful for example, if you want a small texture size for some games," )
    print ("  and you know you use only the first 256 glyphs. However, you should be careful" )
    print ("  as the CoreText's typesetter may select a ligature glyph such as 'fi' and 'ff'" )
    print ("  whose indices are above 255, even if you use only English alphabets." )
    print ("")
    exit(0)
}

if verboseFound {
    print ("sdfontgen : generating signed distance fonts with the following parameters.")
    print ("  font name: [\(fontName)]")
    print ("  glyph number cut-off: [\(glyphNumCutoff)]")
    print ("  spread: [\(spread)]")
    print ("  up-sample factor: [\(upSample)]")
    print ("  texture size: [\(textureSize)]")
    print ("  output path: [\(outputPath)]")
}

let sdGenerator = SDFontGenerator(
    device                             : MTLCreateSystemDefaultDevice()!,
    fontName                           : fontName,
    outputTextureSideLen               : textureSize,
    spreadFactor                       : spread,
    upSamplingFactor                   : upSample,
    glyphNumCutoff                     : glyphNumCutoff,
    verbose                            : verboseFound,
    usePosixPath                       : true
)

let rtn1 = sdGenerator.writeToPNGFile(fileName: fontName, path: outputPath )
if !rtn1 {
    print ("ERROR: cannot write PNG file [\(outputPath)/\(fontName).png]")
}

let rtn2 = sdGenerator.writeMetricsToJSONFile(fileName: fontName, path: outputPath )
if !rtn2 {
    print ("ERROR: cannot write JSON file [\(outputPath)/\(fontName).json]")
}
print ("sdfontgen: finished processing.")
