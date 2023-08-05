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
                        print("update info")
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
                TextField(placeholder, text: $text)
                
                Divider()
            }
        }
        .font(.subheadline)
        .frame(height: 36)
    }
}

struct EditFutureMarkerView_Previews: PreviewProvider {
    static var previews: some View {
        EditFutureMarkerView(viewModel: EditFutureMarkerViewModel(user: User.MOCK_USERS[1]))
    }
}
