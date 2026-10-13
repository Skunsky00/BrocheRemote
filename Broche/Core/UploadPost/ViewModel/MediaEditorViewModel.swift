//
//  MediaEditorViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 10/12/26.
//

import Foundation
import SwiftUI

enum TextStyleOption: CaseIterable {
    case classic, modern, strong, serif, typewriter, script

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .modern: return "Modern"
        case .strong: return "Strong"
        case .serif: return "Serif"
        case .typewriter: return "Typewriter"
        case .script: return "Script"
        }
    }

    func font(size: CGFloat) -> Font {
        switch self {
        case .classic: return .system(size: size, weight: .bold)
        case .modern: return .custom("AvenirNext-Heavy", size: size)
        case .strong: return .custom("Futura-CondensedExtraBold", size: size)
        case .serif: return .custom("Georgia-Bold", size: size)
        case .typewriter: return .custom("Courier-Bold", size: size)
        case .script: return .custom("SnellRoundhand-Bold", size: size)
        }
    }
}

struct TextOverlay: Identifiable {
    let id = UUID()
    var text: String
    var offset: CGSize = .zero
    var scale: CGFloat = 1
    var rotation: Angle = .zero
    var style: TextStyleOption = .classic
    var color: Color = .white
    var fontSize: CGFloat = 40
}

@MainActor
final class MediaEditorViewModel: ObservableObject {
    enum Aspect: CaseIterable {
        case story, portrait, square
        var ratio: CGFloat {
            switch self {
            case .story: return 9.0 / 16.0
            case .portrait: return 4.0 / 5.0
            case .square: return 1
            }
        }
        var label: String {
            switch self {
            case .story: return "Full"
            case .portrait: return "Portrait"
            case .square: return "Square"
            }
        }
        
        static func best(for image: UIImage) -> Aspect {
            let imageRatio = image.size.width / image.size.height
            // compare in log space so "twice as wide" and "half as wide" count as equally far
            return allCases.min {
                abs(log($0.ratio / imageRatio)) < abs(log($1.ratio / imageRatio))
            } ?? .story
        }
    }

    @Published var source: UIImage?
    @Published var aspect: Aspect = .story { didSet { resetTransform() } }
    @Published var scale: CGFloat = 1
    @Published var offset: CGSize = .zero
    @Published var overlays: [TextOverlay] = []
    @Published var draft = TextOverlay(text: "")
    @Published var isEditingText = false
    @Published var editingID: UUID?        // existing text being edited (hidden on canvas meanwhile)
    
    

    var lastScale: CGFloat = 1
    var lastOffset: CGSize = .zero
    private(set) var lastBaked: UIImage?   // lets the view tell "new pick" from "my own output"

    func setSource(_ image: UIImage) {
        source = image
        overlays = []
        aspect = Aspect.best(for: image)
        resetTransform()
    }

    func resetTransform() {
        scale = 1; lastScale = 1
        offset = .zero; lastOffset = .zero
    }

    func beginNewText() {
        draft = TextOverlay(text: "")
        editingID = nil
        withAnimation(.easeOut(duration: 0.15)) { isEditingText = true }
    }

    func beginEditing(_ overlay: TextOverlay) {
        draft = overlay
        editingID = overlay.id
        withAnimation(.easeOut(duration: 0.15)) { isEditingText = true }
    }

    func finishEditing() {
        let trimmed = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = editingID, let i = overlays.firstIndex(where: { $0.id == id }) {
            if trimmed.isEmpty { overlays.remove(at: i) } else { overlays[i] = draft }
        } else if !trimmed.isEmpty {
            overlays.append(draft)
        }
        editingID = nil
        withAnimation(.easeOut(duration: 0.15)) { isEditingText = false }
    }

    func remove(_ overlay: TextOverlay) {
        overlays.removeAll { $0.id == overlay.id }
    }

    /// Renders exactly what the user sees, at ~1080pt wide.
    func render(canvasSize: CGSize) -> UIImage? {
        guard let source else { return nil }
        let canvas = PhotoCanvasView(editor: self, image: source, size: canvasSize, isExporting: true)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1080 / canvasSize.width
        let result = renderer.uiImage
        lastBaked = result
        return result
    }
}
