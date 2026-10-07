//
//  NearbyFriendsViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 10/7/26.
//

import Foundation
import CoreLocation

@MainActor
class NearbyFriendsViewModel: ObservableObject {
    @Published var groups: [NearbyFriendGroup] = []
    @Published var isLoading = false
    @Published var radiusMiles: Double = 25

    let center: CLLocationCoordinate2D
    let placeName: String

    init(center: CLLocationCoordinate2D, placeName: String) {
        self.center = center
        self.placeName = placeName
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        groups = await UserService.fetchNearbyFriendVisits(around: center, radiusMiles: radiusMiles)
    }
}
