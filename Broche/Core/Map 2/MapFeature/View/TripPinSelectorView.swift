//
//  TripPinSelectorView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/10/26.
//

import SwiftUI
import _MapKit_SwiftUI

struct TripPinSelectorView: View {
    @StateObject private var viewModel: TripPinSelectorViewModel
    @State private var tripName: String = ""
    @State private var showNamePrompt = false
    @State private var showError = false
    @Environment(\.dismiss) var dismiss

    let user: User

    init(user: User, existingTrip: Trip? = nil) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: TripPinSelectorViewModel(existingTrip: existingTrip))
        self._tripName = State(initialValue: existingTrip?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mapView

                // MARK: - Top banner: selection count + cancel
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)

                    Spacer()

                    Text("\(viewModel.selectedLocationIds.count) selected")
                        .font(.subheadline.bold())

                    Spacer()

                    Button("Done") {
                        showNamePrompt = true
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.selectedLocationIds.isEmpty)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchLocations(userId: user.id)
            }
            .alert("Name Your Trip", isPresented: $showNamePrompt) {
                TextField("Trip name", text: $tripName)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    Task {
                        let success = await viewModel.saveTrip(userId: user.id, name: tripName)
                        print("DEBUG: TripPinSelectorView received save result: \(success)")
                        if success {
                            dismiss()
                        } else {
                            showError = true
                        }
                    }
                }
            } message: {
                Text("Give this trip a name so you can find it later.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
        }
    }

    private var mapView: some View {
        Map(position: $viewModel.cameraPosition) {
            ForEach(viewModel.visitedLocations) { location in
                Annotation("", coordinate: .init(latitude: location.latitude, longitude: location.longitude)) {
                    ZStack {
                        Image(systemName: "mappin.circle")
                            .foregroundStyle(.white)
                            .font(.system(size: 24))
                            .overlay(
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(viewModel.isSelected(location) ? .green : .red)
                                    .font(.system(size: 24))
                            )
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                        if viewModel.isSelected(location) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white, .green)
                                .offset(x: 10, y: -10)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25)) {
                            viewModel.toggleSelection(for: location)
                        }
                    }
                }
                .annotationTitles(.hidden)
                .annotationSubtitles(.hidden)
            }
        }
        .mapStyle(.standard)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

