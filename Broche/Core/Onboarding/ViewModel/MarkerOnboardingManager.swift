//
//  MarkerOnboardingManager.swift
//  Broche
//
//  Created by Jacob Johnson on 8/18/26.
//

import Foundation
import SwiftUI

enum MarkerOnboardingStep: Int, CaseIterable {
    case unsave
    case edit
    case addPhoto
    case nearby
    case albums
    case done

    var title: String {
        switch self {
        case .unsave: return "Manage this pin"
        case .edit: return "Customize your sheet"
        case .addPhoto: return "Add a photo"
        case .nearby: return "See Friends"
        case .albums: return "Organize with albums"
        case .done: return ""
        }
    }

    var message: String {
        switch self {
        case .unsave: return "Tap the pin icon to remove it."
        case .edit: return "Tap the pencil to edit the location details. Add a caption and a link."
        case .addPhoto: return "Tap the camera to add a photo or video from this place."
        case .nearby: return "Tap Nearby to see friends who've traveled to this same location."
        case .albums: return "Group your photos into albums for trips you've taken here more than once."
        case .done: return ""
        }
    }

    var messageAboveTarget: Bool {
        switch self {
        case .unsave: return false
        case .edit: return false
        case .addPhoto: return false
        case .nearby: return false
        case .albums: return true
        case .done: return false
        }
    }

    var messageOffset: CGFloat {
        switch self {
        case .albums: return 200   // matches the offset that worked for the profile-view steps
        default: return 100
        }
    }
}

@MainActor
class MarkerOnboardingManager: ObservableObject {
    @AppStorage("hasSeenMarkerSheetOnboarding") var hasSeenMarkerSheetOnboarding: Bool = false
    @Published var currentStep: MarkerOnboardingStep = .unsave
    @Published var isShowing: Bool = false

    func start() {
        guard !hasSeenMarkerSheetOnboarding else { return }
        currentStep = .unsave
        isShowing = true
    }

    func advance() {
        guard let currentIndex = MarkerOnboardingStep.allCases.firstIndex(of: currentStep) else { return }
        let nextIndex = currentIndex + 1
        if nextIndex < MarkerOnboardingStep.allCases.count {
            currentStep = MarkerOnboardingStep.allCases[nextIndex]
        }
        if currentStep == .done {
            finish()
        }
    }

    func skip() {
        finish()
    }

    private func finish() {
        hasSeenMarkerSheetOnboarding = true
        isShowing = false
    }
}
