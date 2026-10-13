//
//  PhotoCanvasView.swift
//  Broche
//
//  Created by Jacob Johnson on 10/12/26.
//

import SwiftUI

struct PhotoCanvasView: View {
    @ObservedObject var editor: MediaEditorViewModel
    let image: UIImage
    let size: CGSize
    var isExporting = false

    /// Size of the image when scaled to fill the frame (before zoom)
    private var fillSize: CGSize {
        let imageRatio = image.size.width / image.size.height
        let frameRatio = size.width / size.height
        if imageRatio > frameRatio {
            return CGSize(width: size.height * imageRatio, height: size.height)
        } else {
            return CGSize(width: size.width, height: size.width / imageRatio)
        }
    }

    var body: some View {
        ZStack {
            Color.black

            Image(uiImage: image)
                .resizable()
                .frame(width: fillSize.width, height: fillSize.height)
                .scaleEffect(editor.scale)
                .offset(editor.offset)

            ForEach($editor.overlays) { $overlay in
                if overlay.id != editor.editingID {
                    OverlayTextView(
                        overlay: $overlay,
                        interactive: !isExporting,
                        onTap: { editor.beginEditing(overlay) },
                        onDelete: { editor.remove(overlay) }
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .contentShape(Rectangle())
        .gesture(transformGesture, including: isExporting ? .none : .all)
    }

    private var transformGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { v in
                    editor.offset = CGSize(
                        width: editor.lastOffset.width + v.translation.width,
                        height: editor.lastOffset.height + v.translation.height
                    )
                }
                .onEnded { _ in
                    clampOffset()
                    editor.lastOffset = editor.offset
                },
            MagnificationGesture()
                .onChanged { v in editor.scale = max(1, min(editor.lastScale * v, 5)) }
                .onEnded { _ in
                    editor.lastScale = editor.scale
                    clampOffset()
                    editor.lastOffset = editor.offset
                }
        )
    }

    private func clampOffset() {
        let maxX = max(0, (fillSize.width * editor.scale - size.width) / 2)
        let maxY = max(0, (fillSize.height * editor.scale - size.height) / 2)
        withAnimation(.easeOut(duration: 0.2)) {
            editor.offset.width = min(max(editor.offset.width, -maxX), maxX)
            editor.offset.height = min(max(editor.offset.height, -maxY), maxY)
        }
    }
}

struct OverlayTextView: View {
    @Binding var overlay: TextOverlay
    let interactive: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var startOffset: CGSize = .zero
    @State private var startScale: CGFloat = 1
    @State private var startRotation: Angle = .zero
    @State private var didSetup = false

    var body: some View {
        let label = Text(overlay.text)
            .font(overlay.style.font(size: overlay.fontSize))
            .foregroundStyle(overlay.color)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.45), radius: 3)
            .padding(12)
            .scaleEffect(overlay.scale)
            .rotationEffect(overlay.rotation)
            .offset(overlay.offset)

        if interactive {
            label
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            overlay.offset = CGSize(width: startOffset.width + v.translation.width,
                                                    height: startOffset.height + v.translation.height)
                        }
                        .onEnded { _ in startOffset = overlay.offset }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { v in overlay.scale = max(0.3, min(startScale * v, 6)) }
                        .onEnded { _ in startScale = overlay.scale }
                )
                .simultaneousGesture(
                    RotationGesture()
                        .onChanged { a in overlay.rotation = startRotation + a }
                        .onEnded { _ in startRotation = overlay.rotation }
                )
                .contextMenu { Button("Delete", role: .destructive, action: onDelete) }
                .onAppear {
                    guard !didSetup else { return }
                    didSetup = true
                    startOffset = overlay.offset
                    startScale = overlay.scale
                    startRotation = overlay.rotation
                }
        } else {
            label
        }
    }
}
