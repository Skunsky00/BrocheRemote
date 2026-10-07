//
//  CameraRollImportViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 10/3/26.
//

import Foundation
import _LocationEssentials

@MainActor
final class CameraRollImportViewModel: ObservableObject {
    @Published var suggestions: [PlaceSuggestion] = []
    @Published var isScanning = false
    @Published var isSaving = false
    @Published var scanComplete = false
    @Published var namingProgress: (done: Int, total: Int)?
    @Published var isNaming = false

    private let userId: String
    private let geocoder = CityGeocoder()
    private let fullRescan: Bool
    private var lastScanKey: String { "lastPhotoScan_\(userId)" }

    private var lastScanDate: Date? {
        UserDefaults.standard.object(forKey: lastScanKey) as? Date
    }

    init(userId: String, fullRescan: Bool = false) {
        self.userId = userId
        self.fullRescan = fullRescan
    }

    func scan() async {
        isScanning = true
        var found = await PhotoLocationScanner.scan(since: fullRescan ? nil : lastScanDate)

        let existing = (try? await UserService.fetchSavedLocations(forUserID: userId, type: .visited)) ?? []
        let dedupeRadius: Double = existing.isEmpty ? 1000 : 5000
        found = found.filter { s in
            let loc = CLLocation(latitude: s.coordinate.latitude, longitude: s.coordinate.longitude)
            return !existing.contains {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: loc) < dedupeRadius
            }
        }

        if let homeIdx = found.indices.max(by: { found[$0].assetCount < found[$1].assetCount }) {
            found[homeIdx].isSelected = false
        }

        // Show the list right away
        suggestions = found
        scanComplete = true
        isScanning = false

        await nameAll()
    }

    private func nameAll() async {
        isNaming = true
        defer { isNaming = false; namingProgress = nil }

        let ids = suggestions.map(\.id)
        namingProgress = (0, ids.count)

        for (n, id) in ids.enumerated() {
            if Task.isCancelled { break }
            guard let i = suggestions.firstIndex(where: { $0.id == id }) else { continue }
            if let r = await geocoder.city(for: suggestions[i].coordinate),
               let j = suggestions.firstIndex(where: { $0.id == id }) {
                suggestions[j].cityName = r.displayName
                suggestions[j].cityKey = r.key
            } else if let j = suggestions.firstIndex(where: { $0.id == id }) {
                suggestions[j].namingFailed = true
            }
            namingProgress = (n + 1, ids.count)
        }

        applyFallbackNames()
        disambiguateDuplicates()
    }

    /// Unnamed pins borrow the nearest named pin within 25km.
    private func applyFallbackNames() {
        let named = suggestions.filter { $0.cityName != nil }
        for i in suggestions.indices where suggestions[i].cityName == nil {
            let here = CLLocation(latitude: suggestions[i].coordinate.latitude,
                                  longitude: suggestions[i].coordinate.longitude)
            let nearest = named.min {
                here.distance(from: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)) <
                here.distance(from: CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude))
            }
            if let n = nearest, let name = n.cityName,
               here.distance(from: CLLocation(latitude: n.coordinate.latitude, longitude: n.coordinate.longitude)) < 25_000 {
                suggestions[i].cityName = "Near \(name)"
                suggestions[i].cityKey = n.cityKey
            }
        }
    }

    /// Two pins both called "Anchorage" become "Anchorage" and "Anchorage 2".
    private func disambiguateDuplicates() {
        var seen: [String: Int] = [:]
        for i in suggestions.indices {
            guard let name = suggestions[i].cityName else { continue }
            seen[name, default: 0] += 1
            if seen[name]! > 1 { suggestions[i].cityName = "\(name) \(seen[name]!)" }
        }
    }

    func combineByCity() {
        suggestions = mergeByCity(suggestions)
    }

    private func mergeByCity(_ items: [PlaceSuggestion]) -> [PlaceSuggestion] {
        var merged: [String: PlaceSuggestion] = [:]
        var order: [String] = []
        var unnamed: [PlaceSuggestion] = []

        for s in items {
            guard let key = s.cityKey else { unnamed.append(s); continue }
            if var m = merged[key] {
                let total = m.assetCount + s.assetCount
                let w1 = Double(m.assetCount) / Double(total), w2 = 1 - w1
                m.coordinate = .init(
                    latitude: m.coordinate.latitude * w1 + s.coordinate.latitude * w2,
                    longitude: m.coordinate.longitude * w1 + s.coordinate.longitude * w2)
                m.startDate = min(m.startDate, s.startDate)
                m.endDate = max(m.endDate, s.endDate)
                if s.assetCount > m.assetCount { m.thumbnailAsset = s.thumbnailAsset }
                m.assetCount = total
                merged[key] = m
            } else {
                merged[key] = s
                order.append(key)
            }
        }
        return (order.compactMap { merged[$0] } + unnamed).sorted { $0.startDate < $1.startDate }
    }

    func rename(_ id: UUID, to name: String) {
        guard let i = suggestions.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        suggestions[i].cityName = trimmed.isEmpty ? nil : trimmed
        suggestions[i].namingFailed = trimmed.isEmpty
    }

    func setAll(selected: Bool) {
        for i in suggestions.indices { suggestions[i].isSelected = selected }
    }

    func saveSelected() async -> Int {
        let picked = suggestions.filter { $0.isSelected }
        isSaving = true
        defer { isSaving = false }

        var savedCount = 0
        await withTaskGroup(of: Bool.self) { group in
            for suggestion in picked {
                group.addTask {
                    let location = await Location(
                        id: "",
                        ownerUid: self.userId,
                        latitude: suggestion.coordinate.latitude,
                        longitude: suggestion.coordinate.longitude,
                        city: suggestion.cityName ?? "Unnamed place",   // never save a blank
                        date: Self.formatDateRange(suggestion.startDate, suggestion.endDate),
                        createdAt: suggestion.startDate
                    )
                    return (try? await UserService.saveLocation(uid: self.userId, location: location, type: .visited)) != nil
                }
            }
            for await success in group where success { savedCount += 1 }
        }

        if savedCount > 0 {
            UserDefaults.standard.set(Date(), forKey: lastScanKey)
        }
        return savedCount
    }

    private static func formatDateRange(_ start: Date, _ end: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        let s = f.string(from: start), e = f.string(from: end)
        return s == e ? s : "\(s) – \(e)"
    }
}
