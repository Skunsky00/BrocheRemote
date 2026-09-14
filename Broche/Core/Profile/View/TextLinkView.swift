//
//  TextLinkView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/28/23.
//

import Foundation
import SwiftUI

struct LinkChipView: View {
    let title: String
    let urlString: String
    @State private var showBrowser = false

    private var displayTitle: String {
        title.trimmingCharacters(in: .whitespaces).isEmpty ? cleanedHost : title
    }

    private var cleanedHost: String {
        urlString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
    }

    private var normalizedURL: URL? {
        let lower = urlString.lowercased()
        let full = (lower.hasPrefix("http://") || lower.hasPrefix("https://")) ? urlString : "https://\(urlString)"
        return URL(string: full)
    }

    var body: some View {
        Button {
            showBrowser = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.system(size: 12, weight: .semibold))
                Text(displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color.theme.brocheCoral)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.theme.brocheCoral.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showBrowser) {
            if let url = normalizedURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}
