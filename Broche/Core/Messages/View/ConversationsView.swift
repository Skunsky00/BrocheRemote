//
//  ConversationsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI

struct ConversationsView: View {
    @State var isShowingNewMessageView = false
    @State var showChat = false
    @State var user: User?
    @StateObject var viewModel = ConversationsViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.recentMessages.isEmpty {
                VStack {
                    Spacer()
                    Text("You have no messages")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 0) {   // CHANGED — was default spacing, now 0 since padding lives in the cell
                    ForEach(viewModel.recentMessages) { message in
                        NavigationLink {
                            if let user = message.user {
                                ChatView(user: user)
                            }
                        } label: {
                            ConversationCell(message: message)
                        }
                        Divider()   // MOVED — now between cells, in the parent, not baked into every cell
                            .padding(.leading, 60)   // NEW — inset so it doesn't run under the avatar, matches iOS convention
                    }
                }
                .padding(.horizontal)   // CHANGED — was .padding() (all sides), horizontal only since row padding now handles vertical
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingNewMessageView, content: {
            NewMessageView(show: $isShowingNewMessageView, startChat: $showChat, user: $user)
        })
        .toolbar(content: {
            Button {
                isShowingNewMessageView.toggle()
            } label: {
                Image(systemName: "square.and.pencil")
                    .imageScale(.large)
            }
        })
        .onAppear {
            viewModel.loadData()
            Task {
                await NotificationService.markAllMessageNotificationsAsViewed()   // CHANGED — awaited
                PushBadgeState.shared.hasUnreadMessages = false   // CHANGED — moved after the write completes
            }
        }
        .navigationDestination(isPresented: $showChat) {
            if let user = user {
                ChatView(user: user)
            }
        }
    }
}

struct ConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView()
    }
}

