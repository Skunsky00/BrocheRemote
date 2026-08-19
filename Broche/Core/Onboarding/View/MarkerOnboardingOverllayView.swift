//
//  MarkerOnboardingOverllayView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/18/26.
//

import SwiftUI

struct MarkerOnboardingOverlay: View {
    @ObservedObject var manager: MarkerOnboardingManager
    let frames: [MarkerOnboardingStep: CGRect]

    var body: some View {
        if manager.isShowing, let frame = frames[manager.currentStep], frame != .zero {
            let highlightRect = CGRect(
                x: frame.minX - 8,
                y: frame.minY - 8,
                width: frame.width + 16,
                height: frame.height + 16
            )

            ZStack {
                Color.black.opacity(0.65)
                    .reverseMask {
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: highlightRect.width, height: highlightRect.height)
                            .position(x: highlightRect.midX, y: highlightRect.midY)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                bubble(for: frame)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: manager.currentStep)
        }
    }

    @ViewBuilder
    private func bubble(for frame: CGRect) -> some View {
        VStack(spacing: 12) {
            Text(manager.currentStep.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(manager.currentStep.message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            HStack {
                Button("Skip") { manager.skip() }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button {
                    manager.advance()
                } label: {
                    Text(manager.currentStep == MarkerOnboardingStep.allCases[MarkerOnboardingStep.allCases.count - 2] ? "Done" : "Next")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .frame(width: 280)
        .position(
            x: min(max(frame.midX, 150), UIScreen.main.bounds.width - 150),
            y: manager.currentStep.messageAboveTarget ? frame.minY - manager.currentStep.messageOffset : frame.maxY + manager.currentStep.messageOffset
        )
    }
}

struct MarkerOnboardingTargetKey: PreferenceKey {
    static var defaultValue: [MarkerOnboardingStep: CGRect] = [:]
    static func reduce(value: inout [MarkerOnboardingStep: CGRect], nextValue: () -> [MarkerOnboardingStep: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func markerOnboardingTarget(_ step: MarkerOnboardingStep) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear.preference(key: MarkerOnboardingTargetKey.self, value: [step: proxy.frame(in: .named("onboardingSpace"))])
            }
        )
    }
}
