//
//  UploadStatusToastView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/19/26.
//

import SwiftUI

struct UploadStatusToast: View {
    @ObservedObject var manager = UploadManager.shared

    var body: some View {
        VStack {
            if manager.isUploading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                    Text("Uploading post...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.85))
                .clipShape(Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if manager.uploadFailed {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                    Text("Upload failed. Please try again.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.9))
                .clipShape(Capsule())
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    manager.uploadFailed = false
                }
            }

            Spacer()
        }
        .animation(.easeInOut(duration: 0.25), value: manager.isUploading)
        .animation(.easeInOut(duration: 0.25), value: manager.uploadFailed)
    }
}
