//
//  VisitRowView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/15/26.
//

import SwiftUI
import FirebaseAuth

struct VisitRowView: View {
    let visit: Visit

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 48, height: 48)
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(.secondary)
            }

            Text(visit.name)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

struct VisitListView: View {
    let location: Location
    let isCurrentUser: Bool   // NEW
    @State private var visits: [Visit] = []
    @State private var isLoading = true
    @State private var showCreateAlert = false
    @State private var newVisitName = ""
    @State private var visitPendingDelete: Visit?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Text("Albums")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)

                if isCurrentUser {   // NEW — only owner sees Add
                    HStack {
                        Spacer()
                        Button {
                            showCreateAlert = true
                        } label: {
                            Label("Add", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .markerOnboardingTarget(.albums)
                        .buttonStyle(.plain)
                    }
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if visits.isEmpty {
                Text(isCurrentUser ? "No visits yet. Add one to start posting photos here." : "No visits yet.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(visits) { visit in
                    NavigationLink(destination: VisitPostGridScreen(visit: visit, location: location, isCurrentUser: isCurrentUser)) {
                        VisitRowView(visit: visit)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                            guard isCurrentUser else { return }   // NEW — block delete for non-owners
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            visitPendingDelete = visit
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
        }
        .task {
            await loadVisits()
        }
        .alert("New Visit", isPresented: $showCreateAlert) {
            TextField("Name (e.g. 2020 Trip)", text: $newVisitName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                Task { await createVisit() }
            }
        }
        .alert("Delete this visit?", isPresented: $showDeleteConfirmation, presenting: visitPendingDelete) { visit in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await deleteVisit(visit) }
            }
        } message: { visit in
            Text("This will permanently delete \"\(visit.name)\" and all posts inside it. This can't be undone.")
        }
    }

    private func loadVisits() async {
        isLoading = true
        do {
            visits = try await VisitService.fetchVisits(forUserID: location.ownerUid, locationId: location.id)
        } catch {
            print("DEBUG: Failed to fetch visits: \(error)")
        }
        isLoading = false
    }

    private func createVisit() async {
        guard isCurrentUser, let uid = Auth.auth().currentUser?.uid else { return }   // NEW guard
        do {
            let visit = try await VisitService.createVisit(ownerUid: uid, locationId: location.id, name: newVisitName)
            visits.insert(visit, at: 0)
            newVisitName = ""
        } catch {
            print("DEBUG: Failed to create visit: \(error)")
        }
    }

    private func deleteVisit(_ visit: Visit) async {
        guard isCurrentUser else { return }   // NEW guard
        do {
            try await VisitService.deleteVisit(userId: visit.ownerUid, locationId: visit.locationId, visitId: visit.id)
            visits.removeAll { $0.id == visit.id }
        } catch {
            print("DEBUG: Failed to delete visit: \(error)")
        }
    }
}

struct VisitPostGridScreen: View {
    let visit: Visit
    let location: Location
    let isCurrentUser: Bool   // NEW
    @State private var showUpload = false
    @State private var tabIndex = 0
    @State private var refreshToken = UUID()

    var body: some View {
        PostGridView(config: .visit(visit))
            .id(refreshToken)
            .toolbar {
                if isCurrentUser {   // NEW — only owner can add posts
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showUpload = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showUpload) {
                UploadPostView(
                    tabIndex: $tabIndex,
                    locationId: visit.locationId,
                    visitId: visit.id,
                    locationName: location.city ?? "",
                    onFinished: {
                        showUpload = false
                        refreshToken = UUID()
                    }
                )
            }
    }
}


