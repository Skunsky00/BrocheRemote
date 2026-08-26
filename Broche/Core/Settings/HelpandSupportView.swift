//
//  HelpandSupportView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/25/26.
//

import SwiftUI

struct HelpSupportView: View {
    private let supportEmail = "travelbroche@gmail.com" // CHANGE to your real address
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 0) {
                    AccountActionRow(
                        icon: "envelope.fill",
                        iconColor: .teal,
                        title: "Email Support",
                        subtitle: supportEmail
                    ) {
                        if let url = URL(string: "mailto:\(supportEmail)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Text("Have a question, found a bug, or want to report an issue with another user? Send us an email and we'll get back to you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
