//
//  LocationCommentCell.swift
//  Broche
//
//  Created by Jacob Johnson on 9/8/23.
//

import SwiftUI
import Kingfisher
import FirebaseAuth

struct LocationCommentCell: View {
    let comment: LocationComment
    @ObservedObject var viewModel: LocationCommentViewModel   // NEW
    @Environment(\.colorScheme) var colorScheme

    private var currentUid: String? { Auth.auth().currentUser?.uid }
    private var isLiked: Bool { comment.didLike(uid: currentUid) }

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

                if !comment.likes.isEmpty {
                    Text(comment.likes.count == 1 ? "1 like" : "\(comment.likes.count) likes")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            Button {
                Task { await viewModel.toggleLike(comment) }
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

