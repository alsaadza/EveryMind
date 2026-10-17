import SwiftUI
import PencilKit

/// Apple Pencil (or finger) scratchpad for working problems out by hand. Drawings stay in memory only.
struct ScratchpadView: View {
    var key: String
    @State private var canvas = PKCanvasView()
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Scratchpad · Apple Pencil or finger", systemImage: "pencil.tip").font(.ui(14, .semibold))
                Spacer()
                Button("Clear") { canvas.drawing = PKDrawing() }.buttonStyle(.bordered)
            }
            CanvasRepresentable(canvas: canvas)
                .background(
                    Canvas { g, size in
                        var y: CGFloat = 28
                        while y < size.height { g.stroke(Path { $0.move(to: CGPoint(x: 0, y: y)); $0.addLine(to: CGPoint(x: size.width, y: y)) }, with: .color(.blue.opacity(0.12)), lineWidth: 1); y += 28 }
                    }
                )
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.3)))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Drawing scratchpad")
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    var canvas: PKCanvasView
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 4)
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.overrideUserInterfaceStyle = .light
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
