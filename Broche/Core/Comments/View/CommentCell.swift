//
//  CommentCell.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import SwiftUI
import Kingfisher
import FirebaseAuth

struct CommentCell: View {
    let comment: Comment
    @ObservedObject var viewModel: CommentViewModel   // NEW — needed to call toggleLike
    @Environment(\.colorScheme) var colorScheme

    private var currentUid: String? { Auth.auth().currentUser?.uid }
    private var isLiked: Bool { comment.didLike(uid: currentUid) }   // CHANGED — derived from real data

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            KFImage(URL(string: comment.profileImageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.username)
                        .font(.system(size: 14, weight: .semibold))

                    Text(comment.timestampString ?? "")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Text(comment.commentText)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !comment.likes.isEmpty {   // NEW — show like count when > 0, Instagram-style
                    Text(comment.likes.count == 1 ? "1 like" : "\(comment.likes.count) likes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            Button {
                Task { await viewModel.toggleLike(comment) }   // CHANGED — real call
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 13))
                    .foregroundStyle(isLiked ? .red : .secondary)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
