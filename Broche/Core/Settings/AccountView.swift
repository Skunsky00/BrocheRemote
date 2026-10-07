//
//  AccountView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

struct AccountView: View {
    var onPinsAdded: (() -> Void)? = nil          // NEW

        @State private var showScanOptions = false     // NEW
        @State private var scanMode: ScanMode?         // NEW
        @State private var lastScanDate: Date?         // NEW
    @ObservedObject var viewModel: AccountViewModel
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteErrorMessage: String?
    @State private var showDeleteError = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Header card
                VStack(spacing: 12) {
                    CircularProfileImageView(user: viewModel.user, size: .large)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 3)
                        )
                    
                    VStack(spacing: 2) {
                        Text(viewModel.user.username)
                            .font(.title3.weight(.semibold))
                        Text(viewModel.user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // MARK: - Preferences card
                VStack(spacing: 0) {
                    AccountActionRow(
                        icon: "photo.on.rectangle.angled",
                        iconColor: Color.theme.brocheIndigo,
                        title: "Find Places From My Photos",
                        subtitle: lastScanDate.map { "Last scanned \($0.formatted(date: .abbreviated, time: .omitted))" }
                            ?? "Add pins from where you've taken photos"
                    ) {
                        if lastScanDate == nil {
                            scanMode = .all          // never scanned: just do the full scan
                        } else {
                            showScanOptions = true   // scanned before: let them choose
                        }
                    }

                    Divider().padding(.leading, 60)

                    AccountActionRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        iconColor: .blue,
                        title: "Replay Onboarding Tips",
                        subtitle: "See the intro walkthrough again"
                    ) {
                        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                        UserDefaults.standard.removeObject(forKey: "hasSeenMarkerSheetOnboarding")
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 16)
                
                // MARK: - Danger zone, visually separated
                VStack(spacing: 10) {
                    Text("Danger Zone")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 0) {
                        if isDeleting {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 16)
                                Spacer()
                            }
                        } else {
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundStyle(.red)
                                        .frame(width: 24)
                                    Text("Delete Account")
                                        .foregroundStyle(.red)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    Text("This permanently deletes your profile, pins, posts, and messages. This cannot be undone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete your account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await UserService.deleteAccount(uid: viewModel.user.id)
                        AuthService.shared.signout()
                    } catch {
                        deleteErrorMessage = "Couldn't delete your account. Please log out, log back in, and try again."
                        showDeleteError = true
                    }
                    isDeleting = false
                }
            }
        } message: {
            Text("This cannot be undone.")
        }
        .alert("Error", isPresented: $showDeleteError) {
            Button("OK") { }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
        .confirmationDialog("Find places from my photos", isPresented: $showScanOptions, titleVisibility: .visible) {
            Button("Scan new photos only") { scanMode = .newOnly }
            Button("Scan all photos again") { scanMode = .all }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("New photos only skips anything from before your last scan.")
        }
        .sheet(item: $scanMode, onDismiss: { loadLastScanDate() }) { mode in
            CameraRollImportView(user: viewModel.user, fullRescan: mode == .all) { count in
                if count > 0 { onPinsAdded?() }
            }
        }
        .onAppear { loadLastScanDate() }
    }
    private func loadLastScanDate() {
        lastScanDate = UserDefaults.standard.object(forKey: "lastPhotoScan_\(viewModel.user.id)") as? Date
    }
}

// NEW — reusable icon-labeled row, chevron included, matches the style of your other settings rows
struct AccountActionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

enum ScanMode: Identifiable {
    case newOnly, all
    var id: Int { self == .newOnly ? 0 : 1 }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(viewModel: AccountViewModel(user: User.MOCK_USERS[0]))
    }
}
