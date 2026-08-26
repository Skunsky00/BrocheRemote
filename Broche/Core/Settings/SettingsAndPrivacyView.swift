//
//  SettingsAndPrivacyView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

enum SettingsPrivacyModel: Int, Identifiable, Hashable, CaseIterable {
    case editProfile
    case account
    case savedPosts   // NEW — replaces the old bookmark shortcut from SettingsView
    case notifications
    case privacy
    case verification
    case help
    case terms
    case about
    
    var title: String {
        switch self {
        case .editProfile: return "Edit Profile"
        case .account: return "Account"
        case .savedPosts: return "Saved Posts"
        case .notifications: return "Notifications"
        case .privacy: return "Privacy & Safety"
        case .verification: return "Verification"
        case .help: return "Help & Support"
        case .terms: return "Terms & Privacy Policy"
        case .about: return "About"
        }
    }
    
    var imageName: String {
        switch self {
        case .editProfile: return "person.crop.circle"
        case .account: return "person.text.rectangle"
        case .savedPosts: return "bookmark"
        case .notifications: return "bell.badge"
        case .privacy: return "lock.shield"
        case .verification: return "checkmark.seal"
        case .help: return "questionmark.circle"
        case .terms: return "doc.text"
        case .about: return "info.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .editProfile: return .blue
        case .account: return .gray
        case .savedPosts: return .yellow
        case .notifications: return .red
        case .privacy: return .green
        case .verification: return .purple
        case .help: return .teal
        case .terms: return .indigo
        case .about: return .gray
        }
    }
    
    var section: Int {
        switch self {
        case .editProfile, .account, .savedPosts: return 0
        case .notifications, .privacy: return 1
        case .verification: return 2
        case .help, .terms, .about: return 3
        }
    }
    
    var id: Int { return self.rawValue }
}

struct SettingsAndPrivacyView: View {
    let user: User
    @Binding var selectedOption: SettingsPrivacyModel?
    @State private var showDetail = false
    @State private var showLogoutConfirm = false
    
    private let sectionTitles = ["", "Notifications & Privacy", "Trust", "Support"]
    
    var body: some View {
        List {
            HStack(spacing: 14) {
                CircularProfileImageView(user: user, size: .large)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username)
                        .font(.headline)
                    Text(user.email)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            
            ForEach(0..<4) { sectionIndex in
                Section(header: sectionTitles[sectionIndex].isEmpty ? nil : Text(sectionTitles[sectionIndex])) {
                    ForEach(SettingsPrivacyModel.allCases.filter { $0.section == sectionIndex }) { model in
                        Button {
                            selectedOption = model
                            showDetail = true
                        } label: {
                            SettingsPrivacyRowView(model: model)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Section {
                Button {
                    showLogoutConfirm = true
                } label: {
                    Text("Log Out")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDetail) {
            if let option = selectedOption {
                switch option {
                case .editProfile:
                    EditProfileView(user: user)
                case .account:
                    AccountView(viewModel: AccountViewModel(user: user))
                case .savedPosts:
                    ScrollView {
                        CollectionsView(user: user, disableScrolling: true)
                    }
                    .navigationTitle("Saved")
                case .notifications:
                    NotificationsSettingsView(user: user)
                case .privacy:
                    PrivacyView()
                        .navigationTitle("Privacy")
                case .verification:
                    VerificationRequestView()
                        .navigationTitle("Verification")
                case .help:
                    HelpSupportView()
                case .terms:
                    LegalView()               // CHANGED — was EmptyView()/sheet trigger, now a normal push
                case .about:
                    AboutView()
                }
            }
        }
        .alert("Log out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                AuthService.shared.signout()
            }
        }
    }
}


struct SettingsPrivacyRowView: View {
    let model: SettingsPrivacyModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: model.imageName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(model.iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            
            Text(model.title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())   // THE ACTUAL FIX — makes the entire row hit-testable, not just icon/text
        .padding(.vertical, 4)
    }
}

// NEW — simple placeholder, replace with real version/build info
struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            Text("Broche")
                .font(.title2.bold())
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct SettingsAndPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAndPrivacyView(user: User.MOCK_USERS[0], selectedOption: .constant(nil))
    }
}
