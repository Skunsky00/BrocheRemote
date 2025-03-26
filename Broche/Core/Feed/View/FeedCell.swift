//
//  FeedCell.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import LinkPresentation
import Kingfisher
import AVKit

struct FeedCell: View {
    @ObservedObject var viewModel: FeedCellViewModel
    @State private var showOptionsSheet = false
    @State private var selectedOptionsOption: OptionsItemModel?
    @State private var showDetail = false
    @State private var showDeleteConfirmation = false
    @State private var isCaptionExpanded = false
    @State private var showCommentsSheet = false
    @State private var lastTapTime: Date?
    @Environment(\.colorScheme) var colorScheme
    
    
    var showDeleteOption: Bool { return viewModel.post.isCurrentUser }
    var didLike: Bool { return viewModel.post.didLike ?? false }
    var didBookmark: Bool { return viewModel.post.didBookmark ?? false }
    
    var player: AVPlayer?
    
    init(viewModel: FeedCellViewModel, player: AVPlayer) {
            self.viewModel = viewModel
            self.player = player
        }
    
    var body: some View {
        ZStack {
            // post image
            if let imageUrl = viewModel.post.imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.1)
                    .clipped()
                    .contentShape(Rectangle())
            }
            else if let player = player {
                VideoPlayerController(player: player)
                            .containerRelativeFrame([.horizontal, .vertical])
                            }
            
            VStack(alignment: .leading) {
                
                //user profile and username and location
                HStack {
                    
                    NavigationLink(
                        destination: MapViewForLocation(location: viewModel.post.location),
                        label: {
                            Image(systemName: "mappin")
                                .imageScale(.large)
                                .foregroundColor(.black)
                                .frame(width: 28, height: 28)
                                .background(.thinMaterial)
                                .cornerRadius(10)
                                
                    Text(viewModel.post.location)
                        .font(.footnote)
                })
                    
                    Spacer()
                    
                    if let user = viewModel.post.user {
                        NavigationLink(value: user) {
                            CircularProfileImageView(user: user, size: .xSmall)
                        }
                    }
                }
                .padding(.horizontal,12 )
                .padding(.top, 5)
                
                Spacer()
                
                //MARK: action buttons
                HStack(spacing: 16) {
                    
                    
                    VStack(spacing: 16) {
                        Button {
                            showCommentsSheet.toggle()
                        } label: {
                            VStack {
                                Image(systemName: "bubble.left.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .accentColor(.white)
                                    .foregroundColor(.white)
                                Text(viewModel.commentString)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        
                        Button {
                            selectedOptionsOption = nil
                            showOptionsSheet.toggle()
                        } label: {
                                Image(systemName: "ellipsis")
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                    .accentColor(.white)
                                    .foregroundColor(.white)
                        }
                        
                    }
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button {
                            print("like post")
                            Task { didLike ? try await viewModel.unlike() : try await viewModel.like() }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(didLike ? .red :  .white )
                                NavigationLink(value: SearchViewModelConfig.likes(viewModel.post.id ?? "")) {
                                    Text(viewModel.likeString)
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                            }
                        }

                        
                        Button {
                            print("save post")
                            Task {  didBookmark ? try await viewModel.unbookmark() : try await viewModel.bookmark() }
                        } label: {
                            Image(systemName: "bookmark.fill")
                                .resizable()
                                .frame(width: 22, height: 28)
                                .accentColor(.white )
                                .foregroundColor(didBookmark ? .cyan : .white)
                        }
                    }
                }
                .padding(.bottom, 15)
                .padding(.horizontal, 10)

                
                //likes and comments lable
                HStack {
                    // filter name
                    Text(viewModel.post.label!)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                                        
                    Spacer()
                    
                    Text("\(viewModel.post.user?.username ?? "") ")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                }
                .padding(.horizontal, 16)

                
                // caption - broche description
                HStack {
                    Text("\(viewModel.post.caption) ").font(.system(size: 14)).fontWeight(.semibold).foregroundStyle(.white) //+
                    //Text(viewModel.timestampString)
                      //  .font(.footnote)
                     //   .foregroundColor(.gray)
                }
                .padding()
                .padding(.top, 1)
                
                
                
                
                
            }
//            .containerRelativeFrame([.horizontal, .vertical])
            .sheet(isPresented: $showCommentsSheet, content: {
                CommentsView(post: viewModel.post)
                    .presentationDetents([.fraction(0.8), .large])
                    .presentationDragIndicator(.visible)
            })
            .navigationDestination(isPresented: $showDetail, destination: {
                Text(selectedOptionsOption?.title ?? "")
            })
            .sheet(isPresented: $showOptionsSheet) {
                OptionsView(selectedOption: $selectedOptionsOption, showDeleteOption: showDeleteOption, post: viewModel.post)
                    .presentationDetents([
                        .height(CGFloat(OptionsItemModel.allCases.count * 56))
                    ])
            }
            .onChange(of: selectedOptionsOption) {
                guard let option = selectedOptionsOption else { return }
                if option == .sharepost {
                    showDetail = true
                } else if option == .delete {
                    Task { try await viewModel.deletePost() }
                    //  showDeleteConfirmation.toggle()
                } else {
                    self.showDetail.toggle()
                }
                print(option.title)
            }
            //               .alert(isPresented: $showDeleteConfirmation) {
            //                                          Alert(
            //                                              title: Text("Delete Post"),
            //                                              message: Text("Are you sure you want to delete this post?"),
            //                                              primaryButton: .destructive(Text("Delete")) {
            //                                                  // Call deletePost() on the viewModel
            //                                                  Task { try await viewModel.deletePost() }
            //                                              },
            //                                              secondaryButton: .cancel(Text("Cancel"))
            //                                          )
            //                                      }
            .navigationDestination(for: SearchViewModelConfig.self) { config in
                UserListView(config: config)}
        }
        .onTapGesture {
            // Single tap for play/pause
            switch player!.timeControlStatus {
            case .paused:
                player!.play()
            case .waitingToPlayAtSpecifiedRate, .playing:
                player!.pause()
                handleDoubleTap()
            @unknown default:
                break
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    // Double tap for liking
                    handleDoubleTap()
                }
        )
        

    }
    private func handleDoubleTap() {
            let now = Date()

            if let lastTapTime = lastTapTime, now.timeIntervalSince(lastTapTime) < 0.3 {
                // Perform action on double-tap (e.g., like the post)
                Task {
                    do {
                        try await viewModel.like()
                    } catch {
                        print("Error liking post: \(error)")
                    }
                }
            }

            lastTapTime = now
        }
}
//
//    

//struct FeedCell_Previews: PreviewProvider {
//    static var previews: some View {
//        FeedCell(viewModel: FeedCellViewModel(post: Post.MOCK_POSTS[1]))
//    }
//}
