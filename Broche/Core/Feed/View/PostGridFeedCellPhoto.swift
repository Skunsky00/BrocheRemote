//
//  PostGridFeedCellPhoto.swift
//  Broche
//
//  Created by Jacob Johnson on 8/17/26.
//

import SwiftUI
import Kingfisher
import AVKit
import Firebase

struct PostGridFeedCellPhoto: View {
    @ObservedObject var viewModel: FeedCellViewModel
    @State private var showOptionsSheet = false
    @State private var showSharePostSheet = false
    @State private var selectedOptionsOption: OptionsItemModel?
    @State private var showDetail = false
    @State private var showCommentsSheet = false
    @State private var showBookmarkSheet = false
    @Environment(\.dismiss) var dismiss   // NEW, add to PostGridFeedCellPhoto
    
    var autoOpenComments: Bool = false   // NEW

    var showDeleteOption: Bool { viewModel.post.isCurrentUser }
    var didLike: Bool { viewModel.post.didLike ?? false }
    var didBookmark: Bool { viewModel.post.didBookmark ?? false }

    // NEW — proper 0/1/plural formatting
    private var likeCountText: String {
        switch viewModel.post.likes {
        case 0: return "0 likes"
        case 1: return "1 like"
        default: return "\(viewModel.post.likes) likes"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Header: location + profile pic, above the image
            HStack(spacing: 8) {
                NavigationLink(destination: MapViewForLocation(location: viewModel.post.location)) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                        Text(viewModel.post.location)
                            .font(.subheadline.weight(.semibold))   // CHANGED — was .footnote
                            .lineLimit(1)
                    }
                    .foregroundStyle(.primary)
                }

                Spacer()

                if let user = viewModel.post.user {
                    NavigationLink(destination: ProfileView(user: user)) {   // CHANGED
                        HStack(spacing: 6) {
                            Text(user.username)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            CircularProfileImageView(user: user, size: .xSmall)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 10)

            // MARK: - Image
            if let imageUrl = viewModel.post.imageUrl {
                ZoomableImageView(url: imageUrl)   // CHANGED — was a plain KFImage
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2).onEnded { handleDoubleTap() }
                    )
            }

            // MARK: - Action row: like/comment/bookmark left, ellipsis right
            HStack {
                HStack(spacing: 20) {   // CHANGED — was 18, a touch more breathing room
                    Button {
                        Task { didLike ? try await viewModel.unlike() : try await viewModel.like() }
                    } label: {
                        Image(systemName: didLike ? "heart.fill" : "heart")   // CHANGED — outline when not liked, cleaner than always-filled
                            .resizable()
                            .frame(width: 25, height: 23)
                            .foregroundColor(didLike ? .red : .primary)
                    }

                    Button {
                        showCommentsSheet.toggle()
                    } label: {
                        Image(systemName: "bubble.right")   // CHANGED — .right reads slightly friendlier than .left in this spot
                            .resizable()
                            .frame(width: 24, height: 22)
                            .foregroundColor(.primary)
                    }

                    Button {
                        if didBookmark {
                            Task { try await viewModel.unbookmark() }
                        } else {
                            showBookmarkSheet = true
                        }
                    } label: {
                        Image(systemName: didBookmark ? "bookmark.fill" : "bookmark")   // CHANGED — same outline treatment
                            .resizable()
                            .frame(width: 19, height: 23)
                            .foregroundColor(didBookmark ? .cyan : .primary)
                    }
                }

                Spacer()

                Button {
                    selectedOptionsOption = nil
                    showOptionsSheet.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                        .imageScale(.large)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)   // CHANGED — was 10

            // MARK: - Likes count
            Text(likeCountText)   // CHANGED — now uses the formatted string
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 8)   // CHANGED — was 6

            // MARK: - Caption
            if !viewModel.post.caption.isEmpty {
                CaptionBlock(
                    username: viewModel.post.user?.username ?? "",
                    caption: viewModel.post.caption
                )
                .padding(.horizontal, 16)
                .padding(.top, 5)
            }
            
            // MARK: - View comments
            Button {
                showCommentsSheet = true
            } label: {
                Text("View all \(viewModel.commentString)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)   // CHANGED — was 4

            // MARK: - Timestamp
            Text(viewModel.timestampString)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 6)   // CHANGED — was 4
                .padding(.bottom, 14)   // CHANGED — was 12
        }
        .background(Color(.systemBackground))
        .onAppear {   // NEW
                    if autoOpenComments {
                        showCommentsSheet = true
                    }
                }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsView(post: viewModel.post)
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBookmarkSheet) {
            BookmarkSheet(
                userId: Auth.auth().currentUser?.uid ?? "",
                onSelectCollection: { collection in
                    viewModel.bookmarkPost(collectionId: collection.id ?? "")
                },
                onCreateCollection: { name in
                    viewModel.createCollectionAndBookmark(name: name)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showOptionsSheet) {
            OptionsView(selectedOption: $selectedOptionsOption, showDeleteOption: showDeleteOption, post: viewModel.post)
                .presentationDetents([.height(CGFloat(OptionsItemModel.allCases.count * 56))])
        }
        .onChange(of: selectedOptionsOption) { newValue in
            guard let option = newValue else { return }
            if option == .sharepost {
                showOptionsSheet = false
                showSharePostSheet = true
                selectedOptionsOption = nil
            } else if option == .delete {
                DeleteManager.shared.delete(viewModel.post)   // CHANGED — fire and forget
                dismiss()                                      // CHANGED — leave immediately, no waiting
                selectedOptionsOption = nil
            }
        }
        .sheet(isPresented: $showSharePostSheet) {
            SharePostSheetView(post: viewModel.post)
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func handleDoubleTap() {
        Task {
            do {
                try await viewModel.like()
            } catch {
                print("Error liking post: \(error)")
            }
        }
    }
}

struct ZoomableImageView: View {
    let url: String
    @State private var aspectRatio: CGFloat = 4.0 / 5.0
    @State private var uiImage: UIImage?
    @State private var isZooming = false

    var body: some View {
        KFImage(URL(string: url))
            .onSuccess { result in
                let s = result.image.size
                if s.width > 0, s.height > 0 { aspectRatio = s.width / s.height }
                uiImage = result.image
            }
            .resizable()
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .opacity(isZooming ? 0 : 1)   // hide the original while the floating copy is up
            .overlay(PinchZoomOverlay(image: uiImage, isZooming: $isZooming))
    }
}

struct PinchZoomOverlay: UIViewRepresentable {
    let image: UIImage?
    @Binding var isZooming: Bool

    func makeCoordinator() -> Coordinator { Coordinator(isZooming: $isZooming) }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        v.addGestureRecognizer(pinch)
        context.coordinator.view = v
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.image = image
        context.coordinator.isZooming = $isZooming
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var image: UIImage?
        var isZooming: Binding<Bool>
        weak var view: UIView?
        private var floating: UIImageView?
        private var backdrop: UIView?
        private var startCenter = CGPoint.zero
        private var anchor = CGPoint.zero

        init(isZooming: Binding<Bool>) { self.isZooming = isZooming }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
            guard let view, let window = view.window else { return }

            switch g.state {
            case .began:
                guard let image else { return }
                let frame = view.convert(view.bounds, to: window)

                let dim = UIView(frame: window.bounds)
                dim.backgroundColor = .black
                dim.alpha = 0

                let iv = UIImageView(image: image)
                iv.contentMode = .scaleAspectFit
                iv.frame = frame

                window.addSubview(dim)
                window.addSubview(iv)
                backdrop = dim
                floating = iv
                startCenter = iv.center
                anchor = g.location(in: window)
                isZooming.wrappedValue = true

            case .changed:
                guard let iv = floating else { return }
                let s = min(max(g.scale, 1), 4)
                let loc = g.location(in: window)   // midpoint of both fingers, so moving them pans
                iv.transform = CGAffineTransform(scaleX: s, y: s)
                iv.center = CGPoint(
                    x: anchor.x + (startCenter.x - anchor.x) * s + (loc.x - anchor.x),
                    y: anchor.y + (startCenter.y - anchor.y) * s + (loc.y - anchor.y)
                )
                backdrop?.alpha = min((s - 1) * 0.4, 0.5)

            case .ended, .cancelled, .failed:
                guard let iv = floating else { return }
                UIView.animate(withDuration: 0.3, delay: 0,
                               usingSpringWithDamping: 0.85, initialSpringVelocity: 0,
                               options: []) {
                    iv.transform = .identity
                    iv.center = self.startCenter
                    self.backdrop?.alpha = 0
                } completion: { _ in
                    iv.removeFromSuperview()
                    self.backdrop?.removeFromSuperview()
                    self.floating = nil
                    self.backdrop = nil
                    self.isZooming.wrappedValue = false
                }

            default: break
            }
        }
    }
}
