//
//  FriendsMapView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/27/26.
//

import SwiftUI
import MapKit

// MARK: - Preview data + loader
struct FriendPreview {
    let image: UIImage?
    let pinCount: Int
    let countryCount: Int
    let flags: String
}

@MainActor
final class FriendPreviewLoader: ObservableObject {
    @Published var preview: FriendPreview?
    private static var cache: [String: FriendPreview] = [:]

    func load(for user: User) async {
        if let cached = Self.cache[user.id] { preview = cached; return }

        guard let locs = try? await UserService.fetchSavedLocations(forUserID: user.id, type: .visited),
              !locs.isEmpty else {
            let empty = FriendPreview(image: nil, pinCount: 0, countryCount: 0, flags: "")
            preview = empty
            Self.cache[user.id] = empty
            return
        }

        let countryCodes = Array(Set(locs.compactMap { $0.countryCode?.uppercased() }))
        let flags = countryCodes.prefix(5).map(Self.flag).joined()

        let options = MKMapSnapshotter.Options()
        options.region = Self.region(for: locs)
        options.size = CGSize(width: 340, height: 140)
        options.scale = UIScreen.main.scale

        var image: UIImage?
        if let snap = try? await MKMapSnapshotter(options: options).start() {
            image = UIGraphicsImageRenderer(size: options.size).image { _ in
                snap.image.draw(at: .zero)
                for loc in locs {
                    let p = snap.point(for: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                    let rect = CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10)
                    UIColor.white.setFill(); UIBezierPath(ovalIn: rect.insetBy(dx: -1.5, dy: -1.5)).fill()
                    UIColor.systemRed.setFill(); UIBezierPath(ovalIn: rect).fill()
                }
            }
        }

        let result = FriendPreview(image: image, pinCount: locs.count, countryCount: countryCodes.count, flags: flags)
        Self.cache[user.id] = result
        preview = result
    }

    private static func region(for locs: [Location]) -> MKCoordinateRegion {
        let lats = locs.map { $0.latitude }, lons = locs.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: min(max((lats.max()! - lats.min()!) * 1.6, 5), 160),
            longitudeDelta: min(max((lons.max()! - lons.min()!) * 1.6, 5), 340)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    private static func flag(_ code: String) -> String {
        code.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map { String($0) }.joined()
    }
}

// MARK: - Card
struct FriendMapCard: View {
    let user: User
    @StateObject private var loader = FriendPreviewLoader()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = loader.preview?.image {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Color(.secondarySystemBackground)
                }
            }
            .frame(height: 140)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)

            HStack(spacing: 10) {
                CircularProfileImageView(user: user, size: .xSmall)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username).font(.subheadline.bold())
                    if let p = loader.preview, p.pinCount > 0 {
                        Text("\(p.pinCount) places · \(p.countryCount) \(p.countryCount == 1 ? "country" : "countries")")
                            .font(.caption)
                    } else if loader.preview != nil {
                        Text("No pins yet").font(.caption)
                    }
                }
                Spacer()
                if let flags = loader.preview?.flags { Text(flags).font(.title3) }
            }
            .foregroundStyle(.white)
            .padding(12)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task { await loader.load(for: user) }
    }
}

// MARK: - Sheet
struct FriendsMapView: View {
    @StateObject private var viewModel: SearchViewModel

    init(user: User) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(config: .following(user.id)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.users) { friend in
                        NavigationLink(destination: ProfileView(user: friend)) {
                            FriendMapCard(user: friend)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Friends' Maps")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([ .large])
        .presentationDragIndicator(.visible)
    }
}
