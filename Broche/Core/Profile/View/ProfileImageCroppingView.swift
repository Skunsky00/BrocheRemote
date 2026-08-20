//
//  ProfileImageCroppingView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/19/26.
//

import SwiftUI

struct ProfileImageCropperView: View {
    let image: UIImage
    var onCancel: () -> Void
    var onConfirm: (UIImage) -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // CHANGED — both now scale with screen width instead of fixed constants
    private var visibleSize: CGFloat {
        UIScreen.main.bounds.width - 20   // near-fullscreen stage, small margin each side
    }
    private var cropDiameter: CGFloat {
        UIScreen.main.bounds.width - 60   // crop circle fills most of the width, with room to see context around it
    }

    private var fittedImageSize: CGSize {
        let imgW = image.size.width
        let imgH = image.size.height
        guard imgW > 0, imgH > 0 else { return CGSize(width: cropDiameter, height: cropDiameter) }
        let factor = max(cropDiameter / imgW, cropDiameter / imgH)
        return CGSize(width: imgW * factor, height: imgH * factor)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: fittedImageSize.width, height: fittedImageSize.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: visibleSize, height: visibleSize)
                        .clipped()

                    CircleCutoutMask(cropDiameter: cropDiameter, containerSize: visibleSize)
                        .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(
                    // ... unchanged, all clamp/gesture logic stays exactly the same
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                let proposed = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                offset = clampedOffset(proposed, scale: scale)
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            },
                        MagnificationGesture()
                            .onChanged { value in
                                let proposedScale = max(1.0, lastScale * value)
                                scale = proposedScale
                                offset = clampedOffset(offset, scale: proposedScale)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                lastOffset = offset
                            }
                    )
                )
            }
            .navigationTitle("Move and Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Choose") {
                        let cropped = renderCroppedImage()
                        onConfirm(cropped)
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // UNCHANGED — your working clamp logic, exactly as-is
    private func clampedOffset(_ proposed: CGSize, scale: CGFloat) -> CGSize {
        let scaledW = fittedImageSize.width * scale
        let scaledH = fittedImageSize.height * scale
        let maxX = max(0, (scaledW - cropDiameter) / 2)
        let maxY = max(0, (scaledH - cropDiameter) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    // UNCHANGED — your working render logic, exactly as-is
    private func renderCroppedImage() -> UIImage {
        let renderer = ImageRenderer(content:
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: fittedImageSize.width, height: fittedImageSize.height)
                    .scaleEffect(scale)
                    .offset(offset)
            }
            .frame(width: cropDiameter, height: cropDiameter)
            .clipShape(Circle())
        )
        renderer.scale = image.scale
        return renderer.uiImage ?? image
    }
}

// NEW — the mask: a translucent dark square with a circular hole cut out, sitting ON TOP of the single image
private struct CircleCutoutMask: View {
    let cropDiameter: CGFloat
    let containerSize: CGFloat

    var body: some View {
        Path { path in
            path.addRect(CGRect(x: 0, y: 0, width: containerSize, height: containerSize))
            path.addEllipse(in: CGRect(
                x: (containerSize - cropDiameter) / 2,
                y: (containerSize - cropDiameter) / 2,
                width: cropDiameter,
                height: cropDiameter
            ))
        }
        .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
        .frame(width: containerSize, height: containerSize)
    }
}
