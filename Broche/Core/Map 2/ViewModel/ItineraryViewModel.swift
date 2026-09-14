//
//  ItineraryViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/8/25.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI

class ItineraryViewModel: ObservableObject {
    @Published var travelStats = TravelStats()
    @Published var badges: [Badge] = []
    @Published var showSheet = false
    @Published var visited: [Location] = []
    @Published var trips: [Trip] = []
    @Published var stateGroups: [RegionPinGroup] = []
    @Published var countryGroups: [RegionPinGroup] = []
    @Published var continentGroups: [RegionPinGroup] = []
    @Published var isLoadingStats = false
    
    private var userId: String?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $travelStats
            .map { [weak self] stats in
                let list = self?.buildBadgeList(stats: stats) ?? []
                print("DEBUG: buildBadgeList produced \(list.map { "\($0.title): \($0.isUnlocked)" })")
                return list
            }
            .assign(to: \.badges, on: self)
            .store(in: &cancellables)
    }
    
    func fetchItinerary(userId: String) {
        self.userId = userId
        Task {
            await UserService.backfillRegionData(uid: userId, type: .visited)
            fetchVisitedPins()
            fetchTrips(userId: userId)
        }
    }
    
    func toggleSheet() {
        showSheet.toggle()
    }
    
    func fetchVisitedPins() {
        guard let userId = userId else { return }
        Task {
            do {
                let locations = try await UserService.fetchSavedLocations(forUserID: userId, type: .visited)
                await MainActor.run {
                    self.visited = locations
                    self.isLoadingStats = true
                }
                await computeStats(locations: locations)
                await MainActor.run {
                    self.isLoadingStats = false
                }
            } catch {
                print("DEBUG: Failed to fetch locations: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchTrips(userId: String) {
        Task {
            do {
                let fetched = try await TripService.fetchTrips(forUserID: userId)
                await MainActor.run {
                    self.trips = fetched
                }
            } catch {
                print("DEBUG: Failed to fetch trips: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteTrip(userId: String, tripId: String) {
        Task {
            do {
                try await TripService.deleteTrip(uid: userId, tripId: tripId)
                await MainActor.run {
                    trips.removeAll { $0.id == tripId }
                }
            } catch {
                print("DEBUG: Failed to delete trip: \(error.localizedDescription)")
            }
        }
    }
    
    private func computeStats(locations: [Location]) async {
        var statesDict: [String: [Location]] = [:]
        var countriesDict: [String: [Location]] = [:]
        var continentsDict: [String: [Location]] = [:]

        for location in locations {
            if let state = location.state {
                statesDict[state, default: []].append(location)
            }
            if let country = location.country {
                countriesDict[country, default: []].append(location)
            }
            if let continent = location.continent {
                continentsDict[continent, default: []].append(location)
            }
        }

        let unlockedContinents = continentsDict.keys.compactMap { continent -> String? in
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

        let newStateGroups = statesDict.keys.compactMap { key -> RegionPinGroup? in
            guard let coord = RegionGeography.usStateCentroids[key] else { return nil }
            return RegionPinGroup(id: key, name: usStateNames[key] ?? key.uppercased(), coordinate: coord)
        }.sorted { $0.name < $1.name }

        let newContinentGroups = continentsDict.keys.compactMap { key -> RegionPinGroup? in
            guard let coord = RegionGeography.continentCenters[key] else { return nil }
            return RegionPinGroup(id: key, name: key.capitalized, coordinate: coord)
        }.sorted { $0.name < $1.name }

        var newCountryGroups: [RegionPinGroup] = []
        await withTaskGroup(of: RegionPinGroup?.self) { group in
            for country in countriesDict.keys {
                group.addTask {
                    guard let coord = await RegionGeography.geocodeCountryCenter(country) else { return nil }
                    return RegionPinGroup(id: country, name: country, coordinate: coord)
                }
            }
            for await result in group {
                if let result { newCountryGroups.append(result) }
            }
        }
        newCountryGroups.sort { $0.name < $1.name }

        await MainActor.run {
            self.travelStats = TravelStats(
                visitedStates: statesDict.count,
                visitedCountries: countriesDict.count,
                visitedContinents: continentsDict.count,
                unlockedContinents: unlockedContinents
            )
            self.stateGroups = newStateGroups
            self.countryGroups = newCountryGroups
            self.continentGroups = newContinentGroups
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

struct RegionPinGroup: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

enum RegionType: String, Identifiable {
    case states, countries, continents
    var id: String { rawValue }
    var title: String {
        switch self {
        case .states: return "States Visited"
        case .countries: return "Countries Visited"
        case .continents: return "Continents Visited"
        }
    }
}

// Optional but nicer than showing raw two-letter codes on the map
private let usStateNames: [String: String] = [
    "al":"Alabama","ak":"Alaska","az":"Arizona","ar":"Arkansas","ca":"California",
    "co":"Colorado","ct":"Connecticut","de":"Delaware","fl":"Florida","ga":"Georgia",
    "hi":"Hawaii","id":"Idaho","il":"Illinois","in":"Indiana","ia":"Iowa","ks":"Kansas",
    "ky":"Kentucky","la":"Louisiana","me":"Maine","md":"Maryland","ma":"Massachusetts",
    "mi":"Michigan","mn":"Minnesota","ms":"Mississippi","mo":"Missouri","mt":"Montana",
    "ne":"Nebraska","nv":"Nevada","nh":"New Hampshire","nj":"New Jersey","nm":"New Mexico",
    "ny":"New York","nc":"North Carolina","nd":"North Dakota","oh":"Ohio","ok":"Oklahoma",
    "or":"Oregon","pa":"Pennsylvania","ri":"Rhode Island","sc":"South Carolina",
    "sd":"South Dakota","tn":"Tennessee","tx":"Texas","ut":"Utah","vt":"Vermont",
    "va":"Virginia","wa":"Washington","wv":"West Virginia","wi":"Wisconsin","wy":"Wyoming"
]

private func centroid(of locations: [Location]) -> CLLocationCoordinate2D {
    let lat = locations.map(\.latitude).reduce(0, +) / Double(locations.count)
    let lon = locations.map(\.longitude).reduce(0, +) / Double(locations.count)
    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
}
