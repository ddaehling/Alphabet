import Foundation
import Vision
import CoreImage
import AppKit

let args = CommandLine.arguments
guard args.count >= 3 else { FileHandle.standardError.write("usage: cutout in out\n".data(using:.utf8)!); exit(2) }
guard let nsImg = NSImage(contentsOfFile: args[1]),
      let tiff = nsImg.tiffRepresentation,
      let bmp = NSBitmapImageRep(data: tiff),
      let cg = bmp.cgImage else { FileHandle.standardError.write("load fail\n".data(using:.utf8)!); exit(3) }
let handler = VNImageRequestHandler(cgImage: cg, options: [:])
let req = VNGenerateForegroundInstanceMaskRequest()
do {
    try handler.perform([req])
    guard let res = req.results?.first else { FileHandle.standardError.write("no subject\n".data(using:.utf8)!); exit(4) }
    let pb = try res.generateMaskedImage(ofInstances: res.allInstances, from: handler, croppedToInstancesExtent: false)
    let ci = CIImage(cvPixelBuffer: pb)
    let ctx = CIContext()
    guard let outCG = ctx.createCGImage(ci, from: ci.extent) else { FileHandle.standardError.write("render fail\n".data(using:.utf8)!); exit(5) }
    let rep = NSBitmapImageRep(cgImage: outCG)
    guard let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [NSBitmapImageRep.PropertyKey: Any]()) else { exit(6) }
    try png.write(to: URL(fileURLWithPath: args[2]))
    print("OK \(args[2])")
} catch { FileHandle.standardError.write("err: \(error)\n".data(using:.utf8)!); exit(7) }
