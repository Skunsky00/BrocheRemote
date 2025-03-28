//
//  ItineraryViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/8/25.
//

import Foundation
import Combine
import CoreLocation
import SwiftUICore

class ItineraryViewModel: ObservableObject {
    @Published var travelStats = TravelStats()
    @Published var badges: [Badge] = []
    @Published var showSheet = false
    @Published var visited: [Location] = []
    
    private var userId: String?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $travelStats
            .map { [weak self] stats in
                self?.buildBadgeList(stats: stats) ?? []
            }
            .assign(to: \.badges, on: self)
            .store(in: &cancellables)
    }
    
    func fetchItinerary(userId: String) {
        self.userId = userId
        fetchVisitedPins()
    }
    
    func toggleSheet() {
        showSheet.toggle()
    }
    
    func fetchVisitedPins() {
        guard let userId = userId else { return }
        Task {
            do {
                let locations = try await UserService.fetchSavedLocations(forUserID: userId)
                await MainActor.run {
                    self.visited = locations
                }
                await computeStats(locations: locations)
            } catch {
                print("DEBUG: Failed to fetch locations: \(error.localizedDescription)")
            }
        }
    }
    
    private func computeStats(locations: [Location]) async {
            // List of valid U.S. state codes
            let validUSStates = Set([
                "al", "ak", "az", "ar", "ca", "co", "ct", "de", "fl", "ga",
                "hi", "id", "il", "in", "ia", "ks", "ky", "la", "me", "md",
                "ma", "mi", "mn", "ms", "mo", "mt", "ne", "nv", "nh", "nj",
                "nm", "ny", "nc", "nd", "oh", "ok", "or", "pa", "ri", "sc",
                "sd", "tn", "tx", "ut", "vt", "va", "wa", "wv", "wi", "wy"
            ])
            
            var statesSet = Set<String>()
            var countriesSet = Set<String>()
            var continentsSet = Set<String>()
            
            for location in locations {
                // Validate coordinates
                guard location.latitude != 0.0,
                      location.longitude != 0.0,
                      location.latitude >= -90.0, location.latitude <= 90.0,
                      location.longitude >= -180.0, location.longitude <= 180.0 else {
                    print("DEBUG: Skipping invalid coordinates for location ID: \(location.id) (\(location.latitude), \(location.longitude))")
                    continue
                }
                
                do {
                    let region = try await LocationResolver.resolve(latitude: location.latitude, longitude: location.longitude)
                    
                    // Handle states (U.S.-only)
                    if region.countryCode == "US",
                       let state = region.state?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                       validUSStates.contains(state) {
                        statesSet.insert(state)
                    } else if region.countryCode == "US" {
                        print("DEBUG: Invalid U.S. state for location ID: \(location.id) (\(location.latitude), \(location.longitude)) - State: \(region.state ?? "none")")
                    }
                    
                    // Handle countries and continents (all locations)
                    if let country = region.country?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        countriesSet.insert(country)
                    }
                    if let continent = region.continent?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        continentsSet.insert(continent)
                        if region.countryCode != "US" {
                            print("DEBUG: Non-U.S. location ID: \(location.id) (\(location.latitude), \(location.longitude)) , Continent: \(continent)")
                        }
                    }
                } catch {
                    print("DEBUG: Failed to resolve location ID: \(location.id) (\(location.latitude), \(location.longitude)): \(error.localizedDescription)")
                }
            }
            
            print("DEBUG: Unique states: \(statesSet.sorted()) (count: \(statesSet.count))")
            print("DEBUG: Unique countries: \(countriesSet.sorted()) (count: \(countriesSet.count))")
            print("DEBUG: Unique continents: \(continentsSet.sorted()) (count: \(continentsSet.count))")
        let unlockedContinents = continentsSet.compactMap { continent -> String? in
            switch continent {
            case "north america": return "🟦 North America"
            case "south america": return "🟨 South America"
            case "europe": return "🟪 Europe"
            case "asia": return "🟥 Asia"
            case "oceania": return "🟩 Oceania"
            case "africa": return "⬛ Africa"
            case "antarctica": return "⬜ Antarctica"
            default: return nil
            }
        }
        
        await MainActor.run {
            self.travelStats = TravelStats(
                visitedStates: statesSet.count,
                visitedCountries: countriesSet.count,
                visitedContinents: continentsSet.count,
                unlockedContinents: unlockedContinents
            )
            print("DEBUG: Updated travelStats: States=\(statesSet.count), Countries=\(countriesSet.count), Continents=\(continentsSet.count)")
        }
    }
    
    private func buildBadgeList(stats: TravelStats) -> [Badge] {
        [
            Badge(
                title: "Common Traveler",
                description: "Every journey begins somewhere.",
                color: Color(.sRGB, red: 76/255, green: 175/255, blue: 80/255), // 0xFF4CAF50
                isUnlocked: stats.visitedCountries >= 1 || stats.visitedContinents >= 1
            ),
            Badge(
                title: "Uncommon Traveler",
                description: "You’re on your way!",
                color: Color(.sRGB, red: 33/255, green: 150/255, blue: 243/255), // 0xFF2196F3
                isUnlocked: stats.visitedCountries >= 10 || stats.visitedContinents >= 2
            ),
            Badge(
                title: "Rare Traveler",
                description: "You’ve seen a rare portion of the world.",
                color: Color(.sRGB, red: 156/255, green: 39/255, blue: 176/255), // 0xFF9C27B0
                isUnlocked: stats.visitedCountries >= 30 || stats.visitedContinents >= 4
            ),
            Badge(
                title: "Epic Explorer",
                description: "You’re on an epic journey.",
                color: Color(.sRGB, red: 255/255, green: 152/255, blue: 0/255), // 0xFFFF9800
                isUnlocked: stats.visitedCountries >= 60 || stats.visitedContinents >= 5
            ),
            Badge(
                title: "Legendary Globetrotter",
                description: "You’ve nearly seen it all.",
                color: Color(.sRGB, red: 255/255, green: 235/255, blue: 59/255), // 0xFFFFEB3B
                isUnlocked: stats.visitedCountries >= 100 || stats.visitedContinents >= 6
            )
        ]
    }
}

struct TravelStats {
    let visitedStates: Int
    let visitedCountries: Int
    let visitedContinents: Int
    let unlockedContinents: [String]
    
    init(visitedStates: Int = 0, visitedCountries: Int = 0, visitedContinents: Int = 0, unlockedContinents: [String] = []) {
        self.visitedStates = visitedStates
        self.visitedCountries = visitedCountries
        self.visitedContinents = visitedContinents
        self.unlockedContinents = unlockedContinents
    }
}

struct Badge: Identifiable, Hashable {
    let id: String // Unique identifier (using title)
    let title: String
    let description: String
    let color: Color
    let isUnlocked: Bool
    
    init(title: String, description: String, color: Color, isUnlocked: Bool) {
        self.id = title // Use title as ID since it's unique
        self.title = title
        self.description = description
        self.color = color
        self.isUnlocked = isUnlocked
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Badge, rhs: Badge) -> Bool {
        lhs.id == rhs.id
    }
}
