//
//  MemoryFullScreenReelView.swift
//  Broche
//
//  Created by Jacob Johnson on 11/29/25.
//

import SwiftUI
import AVKit

struct MemoryFullScreenReelView: View {
    let memories: [Memory]
    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(memories.indices, id: \.self) { index in
                    let memory = memories[index]
                    
                    ZStack {
                        // Media
                        if let imageURL = memory.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                        } else if let videoURL = memory.videoURL, let url = URL(string: videoURL) {
                            VideoPlayer(player: AVPlayer(url: url))
                                .onAppear {
                                    AVPlayer(url: url).play()
                                }
                        }
                        
                        // Date overlay (top-left)
                        VStack {
                            HStack {
                                Text(memory.date, format: .dateTime.month(.abbreviated).day().year())
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                                
                                Spacer()
                            }
                            .padding(.top, 50)
                            .padding(.leading, 16)
                            
                            Spacer()
                        }
                        
                        // Caption (bottom)
                        if let caption = memory.caption, !caption.isEmpty {
                            Text(caption)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .padding(.bottom, 60)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Close button + 3-dot menu (owner only)
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.9))
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Three dots — only show if current user owns the pin
                    // We'll add this logic later when we pass user info
                    Button { } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 { dismiss() }
                    if value.translation.width < -100 { dismiss() }
                }
        )
    }
}
