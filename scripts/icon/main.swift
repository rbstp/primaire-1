import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// The icon: the ninja's hooded minifig head, close up, on a blue plate. Drawn
// with Paint and BrickTone so it stays the same blue as the app.

let side = 1024.0

func cg(_ paint: Paint) -> CGColor {
    CGColor(srgbRed: paint.red, green: paint.green, blue: paint.blue, alpha: paint.alpha)
}

/// Core Graphics puts y up; the app puts y down. Everything below is written
/// with y down, like the views, and flipped here.
func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect {
    CGRect(x: x * side, y: side - (y + h) * side, width: w * side, height: h * side)
}

func rounded(_ r: CGRect, _ radius: Double) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius * side, cornerHeight: radius * side, transform: nil)
}

guard let space = CGColorSpace(name: CGColorSpace.sRGB),
      let context = CGContext(
          data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8,
          bytesPerRow: 0, space: space,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
else { fatalError("could not make the bitmap context") }

func fill(_ path: CGPath, _ paint: Paint) {
    context.setFillColor(cg(paint))
    context.addPath(path)
    context.fillPath()
}

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

// The plate: a grid of studs behind him.
let pitch = 1.0 / 8
for row in 0..<8 {
    for column in 0..<8 {
        let x = (Double(column) + 0.5) * pitch
        let y = (Double(row) + 0.5) * pitch
        fill(CGPath(ellipseIn: rect(x - 0.03, y - 0.024, 0.06, 0.048), transform: nil), Palette.cream.opacity(0.07))
    }
}

// The hood, stud included, with a soft drop shadow so it sits on the plate.
context.setShadow(offset: CGSize(width: 0, height: -side * 0.02), blur: side * 0.05, color: cg(Palette.ink.opacity(0.6)))
fill(rounded(rect(0.41, 0.08, 0.18, 0.09), 0.03), Palette.slateLight)
fill(rounded(rect(0.20, 0.14, 0.60, 0.72), 0.16), Palette.slateLight)
context.setShadow(offset: .zero, blur: 0, color: nil)

// A darker lower half so the hood reads as cloth rather than a flat block.
if let cloth = CGGradient(
    colorsSpace: space,
    colors: [cg(Palette.slateLight), cg(Palette.slate)] as CFArray,
    locations: [0, 1]
) {
    context.saveGState()
    context.addPath(rounded(rect(0.20, 0.14, 0.60, 0.72), 0.16))
    context.clip()
    context.drawLinearGradient(cloth, start: CGPoint(x: 0, y: side * 0.86), end: CGPoint(x: 0, y: side * 0.14), options: [])
    context.restoreGState()
}

// The eye slit.
fill(rounded(rect(0.27, 0.46, 0.46, 0.15), 0.075), Palette.skin)

// The headband and its two tails.
fill(rounded(rect(0.15, 0.34, 0.70, 0.12), 0.06), Palette.blade)
context.saveGState()
context.translateBy(x: side * 0.80, y: side - side * 0.40)
context.rotate(by: -0.42)
fill(rounded(CGRect(x: 0, y: -side * 0.03, width: side * 0.22, height: side * 0.055), 0.028), Palette.blade)
context.restoreGState()
context.saveGState()
context.translateBy(x: side * 0.80, y: side - side * 0.38)
context.rotate(by: 0.12)
fill(rounded(CGRect(x: 0, y: -side * 0.02, width: side * 0.19, height: side * 0.045), 0.022), Palette.bladeDeep)
context.restoreGState()

// The eyes, calm, with a glint.
for x in [0.335, 0.575] {
    fill(rounded(rect(x, 0.485, 0.09, 0.10), 0.045), Palette.ink)
    fill(CGPath(ellipseIn: rect(x + 0.018, 0.498, 0.026, 0.026), transform: nil), Palette.cream.opacity(0.85))
}

let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png")
guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("could not encode the icon") }
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not write \(output.path)") }
print("wrote \(output.path)")
