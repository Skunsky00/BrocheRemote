//
//  TripService.swift
//  Broche
//
//  Created by Jacob Johnson on 8/10/26.
//

import Foundation
import FirebaseFirestore

struct TripService {
    
    static func createTrip(uid: String, name: String, locationIds: [String]) async throws -> Trip {
        let docRef = COLLECTION_TRIPS.document(uid).collection("user-trips").document()
        
        let trip = Trip(
            id: docRef.documentID,
            ownerUid: uid,
            name: name,
            locationIds: locationIds,
            createdAt: Date(),
            coverImageUrl: nil
        )
        
        try docRef.setData(from: trip)
        return trip
    }
    
    static func fetchTrips(forUserID uid: String) async throws -> [Trip] {
        let snapshot = try await COLLECTION_TRIPS.document(uid).collection("user-trips").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Trip.self) }
    }
    
    static func updateTrip(uid: String, trip: Trip) async throws {
        let docRef = COLLECTION_TRIPS.document(uid).collection("user-trips").document(trip.id)
        try docRef.setData(from: trip, merge: true)
    }
    
    static func deleteTrip(uid: String, tripId: String) async throws {
        let docRef = COLLECTION_TRIPS.document(uid).collection("user-trips").document(tripId)
        try await docRef.delete()
    }
    static func removeLocationFromAllTrips(uid: String, locationId: String) async throws {
        let trips = try await fetchTrips(forUserID: uid)
        
        for trip in trips where trip.locationIds.contains(locationId) {
            var updated = trip
            updated.locationIds.removeAll { $0 == locationId }
            
            if updated.locationIds.isEmpty {
                try await deleteTrip(uid: uid, tripId: trip.id)   // auto-remove empty trips
            } else {
                try await updateTrip(uid: uid, trip: updated)
            }
        }
    }
}
