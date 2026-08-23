//
//  ChatView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI

struct ChatView: View {
    let user: User
    @StateObject var viewModel: ChatViewModel
    @State var messageText: String = ""
    @GestureState private var dragOffset: CGFloat = 0
    @State private var hasLoadedInitialMessages = false   // NEW
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ChatViewModel(user: user))
    }
    
    private var swipeToRevealGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .updating($dragOffset) { value, state, _ in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard horizontal < 0, abs(horizontal) > abs(vertical) else { return }
                state = max(horizontal, -60)
            }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageView(viewModel: MessageViewModel(message: message), dragOffset: dragOffset)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .simultaneousGesture(swipeToRevealGesture)
                    .padding(.top)
                    .onChange(of: viewModel.messages.count) { _ in
                        guard let lastId = viewModel.messages.last?.id else { return }

                        if !hasLoadedInitialMessages {   // NEW — first population: snap instantly, no animation
                            hasLoadedInitialMessages = true
                            DispatchQueue.main.async {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        } else {   // subsequent new messages: animate normally
                            DispatchQueue.main.async {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                CustomInputView(inputText: $messageText, placeholder: "Message...", action: sendMessage)
                    .padding(10)
            }
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }
    
    func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        viewModel.sendMessage(trimmed)
        messageText = ""
    }
}
