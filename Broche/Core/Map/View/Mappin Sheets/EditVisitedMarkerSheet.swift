//
//  EditVisitedMarkerSheet.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/23.
//

import SwiftUI

struct EditVisitedMarkerSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditVisitedViewModel
    
    init(user: User, location: Location) {
            
                self._viewModel = StateObject(wrappedValue: EditVisitedViewModel(user: user, location: location))
            
        }
    var body: some View {
        VStack{
            // toolbar
            VStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Edit Pin")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    
                    Spacer ()
                    
                    Button {
                        Task { try await viewModel.updateUserData()
                        dismiss()
                                                }
                    } label: {
                        Text("Done")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                EditMarkerRowView(title: "Date", placeholder: "13, Aug, 2023", text: $viewModel.date)
                
                EditMarkerRowView(title: "Description", placeholder: "Add details...", text: $viewModel.description)
                
                EditMarkerRowView(title: "Link", placeholder: "Add link here", text: $viewModel.link)
                if !viewModel.link.isEmpty {
                                      Button(action: {
                                          viewModel.link = "" // Clear the link
                                      }) {
                                          Text("Clear Link")
                                              .font(.subheadline)
                                              .foregroundColor(.red)
                                      }
                                  }

                
                Spacer()
            }
            .padding(.top)
        }
    }
}

struct EditVisitedMarkerSheet_Previews: PreviewProvider {
    static var previews: some View {
        EditVisitedMarkerSheet(user: User.MOCK_USERS[1], location: Location.MOCK_LOCATIONS[0])
    }
}
