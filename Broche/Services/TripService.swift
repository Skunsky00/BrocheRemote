//
//  TripService.swift
//  Broche
//
//  Created by Jacob Johnson on 8/10/26.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

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

extension TripService {
        
    static func saveTrip(trip: Trip) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let savedId = UUID().uuidString
        let saved = SavedTrip(
            id: savedId,
            savedByUid: currentUid,
            originalTripId: trip.id,
            originalOwnerUid: trip.ownerUid,
            createdAt: Date()
        )
        
        let ref = Firestore.firestore()
            .collection("users")
            .document(currentUid)
            .collection("saved-trips")
            .document(savedId)
        
        try ref.setData(from: saved)
    }
        
        static func unsaveTrip(savedTripId: String) async throws {
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            
            try await Firestore.firestore()
                .collection("users")
                .document(currentUid)
                .collection("saved-trips")
                .document(savedTripId)
                .delete()
        }
        
        static func checkIfTripIsSaved(tripId: String) async -> String? {
            guard let currentUid = Auth.auth().currentUser?.uid else { return nil }
            
            guard let snapshot = try? await Firestore.firestore()
                .collection("users")
                .document(currentUid)
                .collection("saved-trips")
                .whereField("originalTripId", isEqualTo: tripId)
                .getDocuments() else { return nil }
            
            return snapshot.documents.first?.documentID
        }
        
        // Returns resolved (Trip, SavedTrip) pairs — silently skips any whose original trip no longer exists
        static func fetchSavedTrips(forUserID userId: String) async throws -> [(trip: Trip, savedInfo: SavedTrip)] {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("saved-trips")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let savedEntries = snapshot.documents.compactMap { try? $0.data(as: SavedTrip.self) }
            
            var results: [(Trip, SavedTrip)] = []
            for saved in savedEntries {
                if let allTrips = try? await TripService.fetchTrips(forUserID: saved.originalOwnerUid),
                   let match = allTrips.first(where: { $0.id == saved.originalTripId }) {
                    results.append((match, saved))
                }
                // if not found, original was deleted — skip silently, matches our earlier graceful-degradation pattern
            }
            
            return results
        }
    
}
