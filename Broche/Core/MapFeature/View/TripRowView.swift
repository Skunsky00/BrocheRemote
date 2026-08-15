//
//  TripRowView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/10/26.
//

import SwiftUI

struct TripRowView: View {
    let trip: Trip
    var onDelete: (() -> Void)? = nil   // NEW — nil means delete isn't available here

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
