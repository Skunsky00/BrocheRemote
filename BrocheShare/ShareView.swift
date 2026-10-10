//
//  ShareView.swift
//  BrocheShare
//
//  Created by Jacob Johnson on 10/7/26.
//

// ShareView.swift  (BrocheShare target ONLY)
import SwiftUI
import MapKit

private struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct ShareView: View {
    @ObservedObject var viewModel: ShareViewModel
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            switch viewModel.stage {
            case .loading, .working:
                ProgressView()
                Text(viewModel.stage == .loading ? "Loading..." : "Finding the place...")
                    .font(.subheadline).foregroundColor(.secondary)
                closeButton("Cancel")

            case .found:
                foundCard

            case .searching, .notFound:
                searchCard

            case .signedOut:
                Image(systemName: "person.crop.circle.badge.exclamationmark").font(.system(size: 44))
                Text("Open Broche and sign in first, then try sharing again.")
                    .multilineTextAlignment(.center)
                closeButton("Close")

            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56)).foregroundColor(.green)
                Text(viewModel.doneMessage).font(.headline).multilineTextAlignment(.center)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onDone() }
                    }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: Found card

    private var foundCard: some View {
        VStack(spacing: 14) {
            if let p = viewModel.place, let lat = p.latitude, let lng = p.longitude {
                let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                Map(
                    coordinateRegion: .constant(MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))),
                    interactionModes: [],
                    annotationItems: [MapPin(coordinate: center)]
                ) { pin in
                    MapMarker(coordinate: pin.coordinate)
                }
                .frame(height: 150)
                .cornerRadius(14)
            }

            VStack(spacing: 4) {
                Text(viewModel.place?.name ?? "").font(.title3).bold().multilineTextAlignment(.center)
                if let sub = viewModel.place?.subtitle, !sub.isEmpty {
                    Text(sub).font(.subheadline).foregroundColor(.secondary)
                }
            }

            if let note = viewModel.foundNote {
                Text(note)
                    .font(.footnote).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: { viewModel.confirm() }) {
                Text(viewModel.confirmTitle)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.accentColor).foregroundColor(.white).cornerRadius(12)
            }

            Button("Wrong place?") { viewModel.startSearch() }
                .foregroundColor(.secondary)
        }
    }

    // MARK: Search card (wrong place, or nothing found)

    private var searchCard: some View {
        VStack(spacing: 12) {
            Text(viewModel.message).font(.subheadline).foregroundColor(.secondary)

            TextField("Search for the place", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { viewModel.search() }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.results, id: \.self) { item in
                        Button {
                            Task { await viewModel.choose(item) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "Unknown").font(.headline)
                                Text([item.placemark.locality, item.placemark.country]
                                    .compactMap { $0 }.joined(separator: ", "))
                                    .font(.footnote).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                        }
                        .disabled(viewModel.busy)
                        Divider()
                    }
                }
            }

            closeButton("Cancel")
        }
    }

    private func closeButton(_ title: String) -> some View {
        Button(title) {
            viewModel.finish()
            onCancel()
        }
        .foregroundColor(.secondary)
    }
}

