//
//  UserCell.swift
//  Broche
//
//  Created by Jacob Johnson on 12/13/22.
//

import SwiftUI
import Kingfisher

struct UserCell: View {
    let user: User
    var body: some View {
        HStack {
            KFImage(URL(string: user.profileImage))
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            
            //vsatck -> username
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(user.fullname)
                    .font(.system(size: 14))
                
            }
           Spacer()
        }
    }
}


