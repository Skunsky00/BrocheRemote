//
//  CommentCell.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import SwiftUI
import Kingfisher

struct CommentCell: View {
    let comment: Comment
    @Environment(\.colorScheme) var colorScheme
    
    var selectedCapsuleColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        VStack {
            HStack {
                KFImage(URL(string: comment.profileImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                
                Text(comment.username).font(.system(size: 14, weight: .semibold)) +
                    Text(" \(comment.commentText)").font(.system(size: 14))
                
                Spacer()
                
                Text(" \(comment.timestampString ?? "")")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }.padding(.horizontal)
            
            Capsule()
                .foregroundColor(selectedCapsuleColor)
                .frame(height: 1)
        }
    }
}
