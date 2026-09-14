//
//  RegionMapView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/26.
//

import SwiftUI
import _MapKit_SwiftUI

struct RegionMapView: View {
    let title: String
    let regions: [RegionPinGroup]
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition

    init(title: String, regions: [RegionPinGroup]) {
        self.title = title
        self.regions = regions
        _cameraPosition = State(initialValue: RegionMapView.fitCamera(to: regions))
    }

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(regions) { region in
                    Annotation(region.name, coordinate: region.coordinate) {
                        VStack(spacing: 2) {
                            Image(systemName: "mappin.circle")
                                .foregroundStyle(.white)
                                .font(.system(size: 24))
                                .overlay(
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(Color.theme.brocheRose)
                                        .font(.system(size: 24))
                                )
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                            Text(region.name)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                    .annotationTitles(.hidden)
                    .annotationSubtitles(.hidden)
                }
            }
            .mapStyle(.standard)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private static func fitCamera(to regions: [RegionPinGroup]) -> MapCameraPosition {
        guard !regions.isEmpty else {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
            ))
        }
        let lats = regions.map { $0.coordinate.latitude }
        let lons = regions.map { $0.coordinate.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.6, 8),
                longitudeDelta: max((maxLon - minLon) * 1.6, 8)
            )
        ))
    }
}

