//
//  OnboardingManager.swift
//  Broche
//
//  Created by Jacob Johnson on 8/18/26.
//

import Foundation
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case searchBar
    case createTrips
    case hideProfile
    case viewTrips
    case done

    var title: String {
        switch self {
        case .searchBar: return "Search for a place"
        case .createTrips: return "Create a trip"
        case .hideProfile: return "See the full map"
        case .viewTrips: return "Browse trips"
        case .done: return ""
        }
    }

    var message: String {
        switch self {
        case .searchBar: return "Search for places you've been or want to go, then drop a pin to add it to your social map."
        case .createTrips: return "Tap here to group your pins into a trip — great for a vacation or road trip with multiple stops."
        case .hideProfile: return "Tap here anytime to hide your profile and see the full map underneath. Tap again to see profile"
        case .viewTrips: return "See your own trips here, plus any trips your friends have saved on their profile"
        case .done: return ""
        }
    }

    var requiredTabIndex: Int? {
        switch self {
        case .searchBar, .createTrips: return 0
        case .hideProfile, .viewTrips: return 3
        case .done: return nil
        }
    }
    var messageAboveTarget: Bool {
        switch self {
        case .searchBar, .createTrips: return false
        case .hideProfile, .viewTrips: return true
        case .done: return false
        }
    }
    var messageOffset: CGFloat {   // NEW — per-step distance from target
            switch self {
            case .searchBar, .createTrips: return 100
            case .hideProfile, .viewTrips: return 200   // raised higher, clears the bottom buttons
            case .done: return 100
            }
        }
    
}

@MainActor
class OnboardingManager: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @Published var currentStep: OnboardingStep = .searchBar
    @Published var targetFrame: CGRect = .zero
    @Published var requestedTabIndex: Int?   // NEW

    var isActive: Bool {
        !hasCompletedOnboarding && currentStep != .done
    }

    init() {
        requestedTabIndex = currentStep.requiredTabIndex   // NEW — set initial tab need right away
    }

    func advance() {
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep) else { return }
        let nextIndex = currentIndex + 1
        if nextIndex < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[nextIndex]
        }
        if currentStep == .done {
            hasCompletedOnboarding = true
        }
        requestedTabIndex = currentStep.requiredTabIndex   // NEW
    }

    func skip() {
        hasCompletedOnboarding = true
        currentStep = .done
        requestedTabIndex = nil
    }
}
