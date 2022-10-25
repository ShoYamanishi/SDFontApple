import Foundation
import MetalKit
import UniformTypeIdentifiers

class SDFontIOHandler {

    struct Metrics : Decodable {
        let x      : Double
        let y      : Double
        let width  : Double
        let height : Double
    }

    static func getFileURL( fileName : String, ext : String, path : String?, usePosixPath : Bool ) -> URL {
#if os(iOS)
        var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
         if let path = path {
            documentsURL = documentsURL.appendingPathComponent( path )
        }
        return documentsURL.appendingPathComponent("\(fileName).\(ext)")
#else
        var documentsURL : URL

        if usePosixPath {
            documentsURL = URL( fileURLWithPath: (path != nil) ? path! : "./" )
        }
        else {
            documentsURL = URL( fileURLWithPath: FileManager.default.currentDirectoryPath )
            if let path = path {
                documentsURL = documentsURL.appendingPathComponent( path )
            }
        }
        return documentsURL.appendingPathComponent("\(fileName).\(ext)")
#endif
    }

    static func loadMetricsFromJSONFile( fileName : String, path : String?, usePosixPath : Bool, verbose : Bool ) -> [CGRect] {

        var outArray : [CGRect] = []

        let fileURL = Self.getFileURL( fileName : fileName, ext : "json", path : path, usePosixPath : usePosixPath )

        if verbose {
            print ("INFO: JSON file path to load [\(fileURL)]: ")
        }
        do {
            let rawData = try  Data( contentsOf: fileURL )
            let decoder = JSONDecoder()
            let jsonData: [Metrics] = try! decoder.decode( [Metrics].self, from: rawData )
            for elem in jsonData {
                outArray.append( CGRect( x: CGFloat(elem.x), y: CGFloat(elem.y), width: CGFloat(elem.width), height: CGFloat(elem.height) ) )
            }
        } catch {
            print ( "ERROR: Cannot read and parse json file \(fileName)." )
        }
        return outArray
    }


    static func writeMetricsToJSONFile( fileName : String, path : String?, usePosixPath : Bool, bounds : [CGRect], verbose : Bool ) -> Bool {
        var array : [Any] = []
        for bound in bounds {
            array.append( ["x" : bound.origin.x, "y" : bound.origin.y, "width" : bound.size.width, "height" : bound.size.height ])
        }

        do {
            let jsonData   = try JSONSerialization.data( withJSONObject: array )
            let jsonString = String( data: jsonData, encoding: String.Encoding.utf8 )
            let fileURL    = Self.getFileURL( fileName : fileName, ext : "json", path : path, usePosixPath : usePosixPath )
            if verbose {
                print ("INFO: JSON file path to write [\(fileURL)]: ")
            }
            try jsonString!.write( to: fileURL, atomically: true, encoding: String.Encoding.utf8 )

        } catch {
            return false
        }
        return true
    }

    static func writeMetricsToTSVFile( fileName : String, path : String?, usePosixPath : Bool, bounds : [CGRect], verbose : Bool ) -> Bool {

        var outStr = ""
        for bound in bounds {
            let str = String( format : "%f\t%f\t%f\t%f\n", bound.origin.x, bound.origin.y, bound.size.width, bound.size.height )
            outStr += str
        }

        do {
            let fileURL = Self.getFileURL( fileName : fileName, ext : "txt", path : path, usePosixPath : usePosixPath )
            if verbose {
                print ("INFO: TSV file path to write [\(fileURL)]: ")
            }
            try outStr.write( to: fileURL, atomically: true, encoding: String.Encoding.utf8 )

        } catch {
            return false
        }
        return true
    }

#if os(iOS)
    static func generateUIImage( buf : MTLBuffer, sidesLenPixels : Int ) -> UIImage? {

        let cgImage = generateCGImage(buf : buf, sidesLenPixels : sidesLenPixels )
        let uiImage = UIImage( cgImage: cgImage! )
        return uiImage
    }
#endif

    static func writeToPNGFile( fileName : String, path : String?, usePosixPath : Bool, buf : MTLBuffer, sidesLenPixels : Int, verbose : Bool ) -> Bool {

        let cgImage = generateCGImage(buf : buf, sidesLenPixels : sidesLenPixels )

        let fileURL = Self.getFileURL( fileName : fileName, ext : "png", path : path, usePosixPath : usePosixPath )

        if verbose {
            print ("INFO: PNG file path to write [\(fileURL)]: ")
        }

        let dest = CGImageDestinationCreateWithURL( fileURL as CFURL, UTType.png.identifier as CFString, 1, nil )

        if let dest = dest {
            CGImageDestinationAddImage( dest, cgImage!, nil );
            return CGImageDestinationFinalize( dest )
        }
        return false
    }

    static func loadTextureFromPNGFile( device : MTLDevice, fileName : String, path : String?, usePosixPath : Bool, verbose : Bool ) -> MTLTexture? {

        let loader = MTKTextureLoader( device : device )

        let fileURL = Self.getFileURL( fileName : fileName, ext : "png", path : path, usePosixPath : usePosixPath )

        if verbose {
            print ("INFO: PNG file path to load [\(fileURL)]: ")
        }
        do {
            let texture = try loader.newTexture(
                URL     : fileURL,
                options : [ .origin: MTKTextureLoader.Origin.bottomLeft,
                            .SRGB: false,
                            .generateMipmaps: NSNumber(booleanLiteral: true)
                          ] )
            return texture
        }
        catch {
            print ("ERROR: Cannot load PNG file \(fileName) for MTLTexture.")
            return nil
        }
    }

    static func generateMTLTexture( device : MTLDevice, buf : MTLBuffer, sidesLenPixels : Int ) -> MTLTexture? {

        let cgImage = generateCGImage(buf : buf, sidesLenPixels : sidesLenPixels )
        let loader  = MTKTextureLoader( device: device )
        do {
            let texture = try loader.newTexture(
                cgImage: cgImage!,
                options:[ .origin: MTKTextureLoader.Origin.bottomLeft,
                          .SRGB: false,
                          .generateMipmaps: NSNumber(booleanLiteral: true)
                        ]
            )
            return texture
        }
        catch {
            print ("ERROR: Cannot generate MTLTexture.")
            return nil
        }
    }
    
    static func generateCGImage(buf : MTLBuffer, sidesLenPixels : Int ) -> CGImage? {

        let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceGray();
        let bitmapInfo = CGBitmapInfo( rawValue: CGImageAlphaInfo.none.rawValue | CGImageByteOrderInfo.orderDefault.rawValue | CGImagePixelFormatInfo.packed.rawValue )

        let context = CGContext(
            data:             buf.contents(),
            width:            sidesLenPixels,
            height:           sidesLenPixels,
            bitsPerComponent: 8,
            bytesPerRow:      sidesLenPixels,
            space:            colorSpace,
            bitmapInfo:       bitmapInfo.rawValue
        )
        context!.setAllowsAntialiasing(false)
        return context!.makeImage()
    }
}

