//
//  MarkerSheet2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import CoreLocation // For CLLocationCoordinate2D in related components
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct MarkerSheet2: View {
    @ObservedObject var viewModel: MarkerSheetViewModel2
    @EnvironmentObject var locationViewModel: LocationSearchViewModel2
    @State private var showEditMarker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack { // Replaced NavigationView with NavigationStack for iOS 18
            VStack {
                // Header
                HStack {
                    Image(systemName: "mappin")
                        .imageScale(.large)
                        .foregroundStyle(viewModel.type == .visited ? .red : .blue)
                    Spacer()
                    Text(viewModel.location.city ?? "Visit") // Use location.city for consistency
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    NavigationLink(destination: LocationsCommentsView(location: viewModel.location, locationType: viewModel.type)) {
                        Image(systemName: "bubble.left")
                            .imageScale(.large)
                            .foregroundStyle(Color(.label))
                    }
                    if viewModel.user.isCurrentUser {
                        Button {
                            showEditMarker.toggle()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .imageScale(.large)
                                .foregroundStyle(Color(.label))
                        }
                        .sheet(isPresented: $showEditMarker) {
                            EditMarkerView2(user: viewModel.user, location: viewModel.location, type: viewModel.type)
                        }
                    } else {
                        Button {
                            // Handle like (e.g., toggle like in Firestore)
                        } label: {
                            Image(systemName: "heart.fill")
                                .imageScale(.large)
                                .foregroundStyle(Color(.label))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Divider()
                
                ScrollView {
                    HStack {
                        NavigationLink(destination: ProfileView(user: viewModel.user)) {
                            CircularProfileImageView(user: viewModel.user, size: .xSmall)
                        }
                        Text(viewModel.user.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            // Open nearby locations (e.g., query Firestore for nearby pins)
                        } label: {
                            Text("Nearby")
                                .font(.footnote)
                                .fontWeight(.semibold)
                            Image(systemName: "mappin.and.ellipse")
                        }
                    }
                    .padding(.horizontal, 10)
                    
                    if let date = viewModel.location.date {
                        HStack {
                            Text(date)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        .padding(.leading)
                    }
                    
                    if let description = viewModel.location.description {
                        HStack {
                            Text(description)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.body)
                        }
                        .padding(.leading)
                        .padding(.vertical, 6)
                    }
                    
                    if let link = viewModel.location.link, viewModel.type == .visited {
                        HStack {
                            TextLinkView(text: link, linkColor: .cyan)
                        }
                        .padding(.leading)
                        .padding(.top)
                    }
                    
                    // Feedback Button
                    if viewModel.user.isCurrentUser {
                        Button {
                            if let url = URL(string: "mailto:feedback@broche.app") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Suggest Feature")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
