//
//  PrivacyView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI
import SafariServices

// NEW — dedicated page for the two legal links
struct LegalView: View {
    @State private var sheetURL: URL?
    
    private let termsURL = URL(string: "https://travelbroche.com/terms")!
    private let privacyURL = URL(string: "https://travelbroche.com/privacy")!
    
    var body: some View {
        List {
            Button {
                sheetURL = termsURL
            } label: {
                HStack {
                    Text("Terms of Service")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Button {
                sheetURL = privacyURL
            } label: {
                HStack {
                    Text("Privacy Policy")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Terms & Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheetURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}

// NEW — makes URL usable with sheet(item:)
extension URL: Identifiable {
    public var id: String { self.absoluteString }
}


struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}



struct PrivacyView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: - Account privacy card
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Private Account")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("Coming soon")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: .constant(false))
                            .labelsHidden()
                            .disabled(true)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Text("Broche doesn't currently support private accounts — everyone can see your posts and pins. This feature may be added in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
