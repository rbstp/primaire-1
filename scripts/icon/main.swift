import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side = 1024.0

func cg(_ paint: Paint) -> CGColor {
    CGColor(srgbRed: paint.red, green: paint.green, blue: paint.blue, alpha: paint.alpha)
}

func point(angle: Double, radius: Double) -> CGPoint {
    CGPoint(x: side / 2 + cos(angle) * radius, y: side / 2 + sin(angle) * radius)
}

/// A four bladed shuriken: a curved cutting edge into each notch, a straight
/// back out to the next tip.
func shuriken(outer: Double, inner: Double) -> CGPath {
    let path = CGMutablePath()
    let quarter = Double.pi / 2
    let start = quarter / 2
    path.move(to: point(angle: start, radius: outer))
    for index in 0..<4 {
        let tip = start + Double(index) * quarter
        let notch = tip + quarter / 2
        path.addQuadCurve(
            to: point(angle: notch, radius: inner),
            control: point(angle: tip + quarter * 0.28, radius: (outer + inner) * 0.42)
        )
        path.addLine(to: point(angle: tip + quarter, radius: outer))
    }
    path.closeSubpath()
    return path
}

guard let space = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
          data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8,
          bytesPerRow: 0, space: space,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
else { fatalError("could not make the bitmap context") }

context.setFillColor(cg(Palette.bladeDeep))
context.fill(CGRect(x: 0, y: 0, width: side, height: side))

if let sky = CGGradient(
    colorsSpace: space,
    colors: [cg(Palette.blade), cg(Palette.bladeDeep), cg(Palette.night)] as CFArray,
    locations: [0, 0.62, 1]
) {
    context.drawLinearGradient(
        sky,
        start: CGPoint(x: side * 0.15, y: side),
        end: CGPoint(x: side * 0.85, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

// A faint moon behind the blade so the black shape always has something to sit on.
context.setFillColor(cg(Palette.azure.opacity(0.16)))
context.fillEllipse(in: CGRect(x: side * 0.16, y: side * 0.16, width: side * 0.68, height: side * 0.68))

let blade = shuriken(outer: side * 0.40, inner: side * 0.125)
context.setShadow(offset: CGSize(width: 0, height: -side * 0.012), blur: side * 0.03, color: cg(Palette.ink.opacity(0.55)))
context.setFillColor(cg(Palette.ink))
context.addPath(blade)
context.fillPath()
context.setShadow(offset: .zero, blur: 0, color: nil)

context.setStrokeColor(cg(Palette.cream.opacity(0.85)))
context.setLineWidth(side * 0.014)
context.setLineJoin(.round)
context.addPath(blade)
context.strokePath()

let hub = side * 0.072
context.setFillColor(cg(Palette.cream))
context.fillEllipse(in: CGRect(x: side / 2 - hub, y: side / 2 - hub, width: hub * 2, height: hub * 2))
context.setFillColor(cg(Palette.ink))
context.fillEllipse(in: CGRect(x: side / 2 - hub * 0.52, y: side / 2 - hub * 0.52, width: hub * 1.04, height: hub * 1.04))

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png")
guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("could not encode the icon") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(output.path)") }
print("wrote \(output.path)")
