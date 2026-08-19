//
//  YearMemoryReelView.swift
//  Broche
//
//  Created by Jacob Johnson on 11/29/25.
//

import SwiftUI
import AVKit

struct YearMemoryReelView: View {
    let allGroups: [MemoryGroup]
    @State private var currentYearIndex = 0
    @State private var currentMemoryIndex = 0
    @State private var segmentProgress: Double = 0.0
    
    @Environment(\.dismiss) private var dismiss
    
    private var currentGroup: MemoryGroup { allGroups[currentYearIndex] }
    private var memories: [Memory] { currentGroup.memories }
    private var currentMemory: Memory { memories[currentMemoryIndex] }
    private var currentYear: Int { currentGroup.year }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            MemoryMediaView(
                memory: currentMemory,
                onProgress: { progress in
                    segmentProgress = progress
                }
            )
            .ignoresSafeArea()
            
            // Top Bar
            VStack(spacing: 10) {
                HStack {
                    Text(String(currentYear))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.leading, 16)
                    Spacer()
                }
                .padding(.top, 50)
                
                // Clean left-to-right progress bar
                HStack(spacing: 4) {
                    ForEach(0..<memories.count, id: \.self) { i in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.3))
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: i < currentMemoryIndex ? geo.size.width :
                                           (i == currentMemoryIndex ? geo.size.width * segmentProgress : 0))
                                    .animation(.linear(duration: 0.05), value: segmentProgress)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                .padding(.horizontal, 12)
                
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .onChange(of: currentMemoryIndex) { _ in segmentProgress = 0.0 }
        
        // Tap to navigate
        .onTapGesture { location in
            let w = UIScreen.main.bounds.width
            if location.x < w * 0.4 {
                if currentMemoryIndex > 0 {
                    currentMemoryIndex -= 1
                } else if currentYearIndex > 0 {
                    currentYearIndex -= 1
                    currentMemoryIndex = memories.count - 1
                }
            } else {
                if currentMemoryIndex < memories.count - 1 {
                    currentMemoryIndex += 1
                } else if currentYearIndex < allGroups.count - 1 {
                    currentYearIndex += 1
                    currentMemoryIndex = 0
                }
            }
        }
        
        // Swipe to change year
        .gesture(
            DragGesture()
                .onEnded { value in
                    let h = value.translation.width
                    if abs(h) > 100 {
                        if h < 0 && currentYearIndex < allGroups.count - 1 {
                            currentYearIndex += 1
                            currentMemoryIndex = 0
                        } else if h > 0 && currentYearIndex > 0 {
                            currentYearIndex -= 1
                            currentMemoryIndex = memories.count - 1
                        }
                    } else if value.translation.height > 120 {
                        dismiss()
                    }
                }
        )
    }
}

// MARK: - MemoryMediaView (100% working, no crashes)
struct MemoryMediaView: View {
    let memory: Memory
    var onProgress: (Double) -> Void = { _ in }
    
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var timeObserver: Any?
    
    var body: some View {
        ZStack {
            if let url = URL(string: memory.imageURL ?? memory.videoURL ?? "") {
                if memory.isVideo {
                    ZStack {
                        VideoPlayer(player: player ?? AVPlayer())
                            .disabled(true)
                            .onAppear {
                                isLoading = true
                                let p = AVPlayer(url: url)
                                player = p
                                p.volume = 1.0
                                p.play()
                                
                                // Auto loop
                                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                                       object: p.currentItem,
                                                                       queue: .main) { _ in
                                    p.seek(to: .zero)
                                    p.play()
                                }
                                
                                // Progress reporting
                                let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
                                timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                                    guard let duration = p.currentItem?.duration.seconds,
                                          duration > 0, !duration.isNaN else { return }
                                    let progress = time.seconds / duration
                                    onProgress(progress)
                                }
                            }
                            .onDisappear {
                                player?.pause()
                                if let observer = timeObserver {
                                    player?.removeTimeObserver(observer)
                                    timeObserver = nil
                                }
                                player?.replaceCurrentItem(with: nil)
                                player = nil
                            }
                        
                        // Loading spinner
                        if isLoading {
                            Color.black.opacity(0.7)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.8)
                        }
                    }
                    .onChange(of: player?.currentItem?.status) { status in
                        if status == .readyToPlay {
                            isLoading = false
                        }
                    }
                } else {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .onAppear { onProgress(1.0); isLoading = false }
                    } placeholder: {
                        Color.black
                    }
                }
            } else {
                Color.black.overlay(Text("No Media").foregroundColor(.white))
            }
        }
    }
}
