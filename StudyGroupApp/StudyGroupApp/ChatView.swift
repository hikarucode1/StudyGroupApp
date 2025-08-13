import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: AppViewModel
    let room: Room
    @State private var messageText = ""
    @State private var showingEmojiPicker = false
    @FocusState private var isTextFieldFocused: Bool
    
    var chatMessages: [ChatMessage] {
        viewModel.getChatMessages(for: room.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            ChatHeader(room: room, viewModel: viewModel)
            
            // メッセージ一覧
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatMessages) { message in
                            ChatMessageRow(message: message, isCurrentUser: message.userId == viewModel.currentUser?.id)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .onChange(of: chatMessages.count) { _ in
                    // 新しいメッセージが追加されたら自動スクロール
                    if let lastMessage = chatMessages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // 入力エリア
            ChatInputArea(
                messageText: $messageText,
                onSend: sendMessage,
                onEmoji: { showingEmojiPicker = true }
            )
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView(onEmojiSelected: { emoji in
                messageText += emoji
                showingEmojiPicker = false
            })
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendChatMessage(message: messageText, roomId: room.id)
        messageText = ""
    }
}

// MARK: - チャットヘッダー
struct ChatHeader: View {
    let room: Room
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(room.participants.count)人参加中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 参加者アイコン
            ParticipantsIconRow(participants: room.participants)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
}

// MARK: - チャットメッセージ行
struct ChatMessageRow: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.message)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // ユーザーアイコン
                UserAvatar(profileImage: message.userProfileImage, customProfileImageData: message.customProfileImageData, size: 32)
            } else {
                // ユーザーアイコン
                UserAvatar(profileImage: message.userProfileImage, customProfileImageData: message.customProfileImageData, size: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    if message.messageType == .system {
                        // システムメッセージ
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text(message.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        // 通常メッセージ
                        Text(message.userName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(message.message)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(16)
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - ユーザーアバター
struct UserAvatar: View {
    let profileImage: String?
    let customProfileImageData: Data?
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: size, height: size)
            
            if let customProfileImageData = customProfileImageData,
               let customImage = UIImage(data: customProfileImageData) {
                Image(uiImage: customImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: profileImage ?? "person.circle.fill")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - チャット入力エリア
struct ChatInputArea: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let onEmoji: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEmoji) {
                Image(systemName: "face.smiling")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            TextField("メッセージを入力...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .lineLimit(1...4)
            
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

// MARK: - 絵文字ピッカー
struct EmojiPickerView: View {
    let onEmojiSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let emojis = ["👍", "❤️", "🎉", "🔥", "💪", "📚", "🏃‍♂️", "🧘‍♀️", "☕️", "🌅", "🌙", "⭐️"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("絵文字を選択")
                    .font(.headline)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            onEmojiSelected(emoji)
                        }) {
                            Text(emoji)
                                .font(.system(size: 40))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView(viewModel: AppViewModel(), room: Room(name: "テスト部屋", tags: ["テスト"], createdBy: UUID()))
} 