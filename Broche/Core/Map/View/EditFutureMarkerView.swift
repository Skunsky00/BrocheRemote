//
//  EditFutureMarkerView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/4/23.
//

import SwiftUI

struct EditFutureMarkerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditFutureMarkerViewModel
    
    
    init(user: User, location: Location) {
            
                self._viewModel = StateObject(wrappedValue: EditFutureMarkerViewModel(user: user, location: location))
            
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
                    
                    Text("Edit Profile")
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
                
            }
            Spacer()
        }
    }
}

struct EditMarkerRowView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        
        HStack {
            Text(title)
                .padding(.leading, 8)
                .frame(width: 100, alignment: .leading)
            
            VStack {
                TextField(placeholder, text: $text, axis: .vertical)
                
                Divider()
            }
        }
        .font(.subheadline)
        .frame(height: 70)
    }
}

struct EditFutureMarkerView_Previews: PreviewProvider {
    static var previews: some View {
        EditFutureMarkerView(user: User.MOCK_USERS[1], location: Location.MOCK_LOCATIONS[0] )
    }
}
