//
//  AccountView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var viewModel: AccountViewModel
    var body: some View {
        VStack {
            HStack{
                
                    CircularProfileImageView(user: viewModel.user, size: .large)
                
            }
            .padding(.vertical)
            
            Divider()
            
            HStack {
                Text("Username:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                     Text(viewModel.user.username)
                        .frame(maxWidth: .infinity, alignment: .leading)
                
                    
            }
            .padding(.leading, 10)
            .padding(.vertical)
            
           Divider()
            
            HStack{
                Text("Email:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                    Text(viewModel.user.email)
                        .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 10)
            .padding(.vertical)
            
            Spacer()
        }
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView(viewModel: AccountViewModel(user: User.MOCK_USERS[0]))
    }
}
