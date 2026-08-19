//
//  TripRowView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/10/26.
//

import SwiftUI

struct TripRowView: View {
    let trip: Trip
    var onDelete: (() -> Void)? = nil
    var savedFromUsername: String? = nil   // NEW

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "map.fill")
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.subheadline.bold())
                Text("\(trip.locationIds.count) stops")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let savedFromUsername {   // NEW
                    Text("Saved from @\(savedFromUsername)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
        .onLongPressGesture {
            if onDelete != nil {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showDeleteConfirmation = true
            }
        }
        .alert("Delete Trip?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("This will delete \"\(trip.name)\". Your pins will not be affected.")
        }
    }
}

struct TripListView: View {
    let trips: [Trip]
    let onSelectTrip: (Trip) -> Void
    var onDeleteTrip: ((Trip) -> Void)? = nil   // NEW

    var body: some View {
        VStack(spacing: 10) {
            ForEach(trips) { trip in
                Button {
                    onSelectTrip(trip)
                } label: {
                    TripRowView(trip: trip, onDelete: onDeleteTrip != nil ? { onDeleteTrip?(trip) } : nil)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SavedTripsListView: View {
    let user: User
    @State private var savedTrips: [(trip: Trip, savedInfo: SavedTrip, owner: User)] = []   // CHANGED
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if savedTrips.isEmpty {
                Text("No saved trips yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(savedTrips, id: \.savedInfo.id) { entry in
                    NavigationLink(destination: ProfileView(user: entry.owner, deepLinkTripId: entry.trip.id)) {
                        TripRowView(
                            trip: entry.trip,
                            onDelete: {
                                Task { await unsave(entry.savedInfo.id) }
                            },
                            savedFromUsername: entry.owner.username
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
        .task {
            await loadSavedTrips()
        }
    }

    private func loadSavedTrips() async {
        isLoading = true
        do {
            let resolved = try await TripService.fetchSavedTrips(forUserID: user.id)
            var withOwners: [(Trip, SavedTrip, User)] = []
            for (trip, savedInfo) in resolved {
                if let owner = try? await UserService.fetchUser(withUid: savedInfo.originalOwnerUid) {
                    withOwners.append((trip, savedInfo, owner))
                }
                // if owner fetch fails, skip — same graceful-degradation pattern as deleted trips
            }
            savedTrips = withOwners
        } catch {
            print("DEBUG: Failed to fetch saved trips: \(error)")
        }
        isLoading = false
    }

    private func unsave(_ savedTripId: String) async {
        do {
            try await TripService.unsaveTrip(savedTripId: savedTripId)
            savedTrips.removeAll { $0.savedInfo.id == savedTripId }
        } catch {
            print("DEBUG: Failed to unsave trip: \(error)")
        }
    }
}
