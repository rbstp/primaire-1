import SwiftUI

/// A brick picture: the object he has to name. One Canvas draws every brick,
/// and VoiceOver never says which object it is, because that is the answer.
struct BrickPictureView: View {
    let picture: BrickPicture

    var body: some View {
        GeometryReader { frame in
            let unit = min(
                frame.size.width / CGFloat(picture.columns),
                frame.size.height / CGFloat(picture.rows)
            )
            Canvas(opaque: false, rendersAsynchronously: false) { context, _ in
                for cell in picture.cells {
                    draw(cell, unit: unit, in: &context)
                }
            }
            .frame(width: unit * CGFloat(picture.columns), height: unit * CGFloat(picture.rows))
            .frame(width: frame.size.width, height: frame.size.height)
        }
        .aspectRatio(CGFloat(picture.columns) / CGFloat(picture.rows), contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Un objet à reconnaître")
    }

    /// One brick: the underside, the face, and a stud on top.
    private func draw(_ cell: BrickPicture.Cell, unit: CGFloat, in context: inout GraphicsContext) {
        let tone = tone(cell.tone)
        let corner = unit * 0.12
        let x = CGFloat(cell.x) * unit
        let y = CGFloat(cell.y) * unit

        let underside = CGRect(x: x + unit * 0.04, y: y + unit * 0.2, width: unit * 0.92, height: unit * 0.8)
        context.fill(Path(roundedRect: underside, cornerRadius: corner), with: .color(tone.shade.color))
        let face = CGRect(x: x + unit * 0.04, y: y + unit * 0.06, width: unit * 0.92, height: unit * 0.76)
        context.fill(Path(roundedRect: face, cornerRadius: corner), with: .color(tone.face.color))
        let stud = CGRect(x: x + unit * 0.3, y: y - unit * 0.06, width: unit * 0.4, height: unit * 0.24)
        context.fill(Path(ellipseIn: stud), with: .color(tone.stud.color))
    }

    private func tone(_ tone: BrickPicture.Tone) -> BrickTone {
        switch tone {
        case .blue: .blue
        case .azure: .azure
        case .black: .black
        case .cream: .cream
        case .gold: .gold
        }
    }
}
