//
//  DeleteStatusToast.swift
//  Broche
//
//  Created by Jacob Johnson on 8/21/26.
//

import SwiftUI

struct DeleteStatusToast: View {
    @ObservedObject var manager = DeleteManager.shared

    var body: some View {
        VStack {
            if manager.didDeletePost {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                    Text("Post deleted")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.85))
                .clipShape(Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.25), value: manager.didDeletePost)
    }
}
