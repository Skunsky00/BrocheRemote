//
//  PhotoLocationScanner.swift
//  Broche
//
//  Created by Jacob Johnson on 10/3/26.
//

import Foundation
import Photos
import CoreLocation

struct PlaceSuggestion: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var assetCount: Int
    var startDate: Date
    var endDate: Date
    var thumbnailAsset: PHAsset
    var cityName: String?
    var cityKey: String?
    var isSelected = true
    var namingFailed = false
}

enum PhotoLocationScanner {
    private struct Cluster {
        var sumLat = 0.0, sumLon = 0.0, count = 0
        var first: (asset: PHAsset, date: Date)
        var last: Date
        var centroid: CLLocationCoordinate2D {
            .init(latitude: sumLat / Double(count), longitude: sumLon / Double(count))
        }
        mutating func add(_ asset: PHAsset, _ c: CLLocationCoordinate2D, _ d: Date) {
            sumLat += c.latitude; sumLon += c.longitude; count += 1
            if d < first.date { first = (asset, d) }
            if d > last { last = d }
        }
    }

    static func scan(since: Date? = nil, clusterRadiusMeters: Double = 5_000) async -> [PlaceSuggestion] {
        let status = await requestAccess()
        guard status == .authorized || status == .limited else { return [] }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        if let since {
            options.predicate = NSPredicate(format: "creationDate > %@", since as NSDate)
        }
        let assets = PHAsset.fetchAssets(with: .image, options: options)

        var clusters: [Cluster] = []
        assets.enumerateObjects { asset, _, _ in
            guard let loc = asset.location, let date = asset.creationDate else { return }
            let p = loc.coordinate
            let here = CLLocation(latitude: p.latitude, longitude: p.longitude)

            if let idx = clusters.firstIndex(where: {
                let c = $0.centroid
                return CLLocation(latitude: c.latitude, longitude: c.longitude).distance(from: here) < clusterRadiusMeters
            }) {
                clusters[idx].add(asset, p, date)
            } else {
                var c = Cluster(first: (asset, date), last: date)
                c.add(asset, p, date)
                clusters.append(c)
            }
        }

        return clusters.map {
            PlaceSuggestion(coordinate: $0.centroid, assetCount: $0.count,
                            startDate: $0.first.date, endDate: $0.last,
                            thumbnailAsset: $0.first.asset)
        }
        .sorted { $0.startDate < $1.startDate }
    }

    private static func requestAccess() async -> PHAuthorizationStatus {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { cont.resume(returning: $0) }
        }
    }
}


actor CityGeocoder {
    struct Result {
        let displayName: String   // "Austin, TX" or "Lisbon, Portugal"
        let key: String           // used to merge clusters
    }

    private let geocoder = CLGeocoder()
    private var cache: [String: Result] = [:]
    private var lastRequest = Date.distantPast
    private let minInterval: TimeInterval = 1.3   // ~46/min, under Apple's limit

    func city(for coord: CLLocationCoordinate2D) async -> Result? {
        // ~5km grid cell cache
        let cell = "\((coord.latitude * 20).rounded())_\((coord.longitude * 20).rounded())"
        if let hit = cache[cell] { return hit }

        for attempt in 0..<4 {
            let wait = minInterval - Date().timeIntervalSince(lastRequest)
            if wait > 0 { try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
            lastRequest = Date()

            do {
                let marks = try await geocoder.reverseGeocodeLocation(
                    CLLocation(latitude: coord.latitude, longitude: coord.longitude),
                    preferredLocale: Locale(identifier: "en_US")
                )
                guard let m = marks.first else { return nil }

                let city = m.locality ?? m.subAdministrativeArea ?? m.administrativeArea ?? m.country
                guard let city else { return nil }

                // Neighborhood if it adds info and isn't just a street address
                let hood = [m.subLocality, m.areasOfInterest?.first]
                    .compactMap { $0 }
                    .first { $0 != city && !$0.contains(where: \.isNumber) }

                let isUS = m.isoCountryCode == "US"
                let region = isUS ? m.administrativeArea : m.country

                var parts: [String] = []
                if let hood { parts.append(hood) }
                parts.append(city)
                if hood == nil, let region, region != city { parts.append(region) }
                let display = parts.joined(separator: ", ")

                let key = [city, m.administrativeArea, m.isoCountryCode]
                    .compactMap { $0 }.joined(separator: "|")

                let result = Result(displayName: display, key: key)
                cache[cell] = result
                return result
            } catch let error as CLError where error.code == .network {
                // throttled: back off and retry
                try? await Task.sleep(nanoseconds: UInt64((attempt + 1) * 8) * 1_000_000_000)
            } catch {
                return nil
            }
        }
        return nil
    }
}
