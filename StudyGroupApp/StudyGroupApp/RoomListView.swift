import SwiftUI

struct RoomListView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingCreateRoom = false
    @State private var searchText = ""
    
    var filteredRooms: [Room] {
        if searchText.isEmpty {
            return viewModel.rooms
        } else {
            return viewModel.rooms.filter { room in
                room.name.localizedCaseInsensitiveContains(searchText) ||
                room.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 現在の部屋情報
                if let currentRoom = viewModel.currentRoom,
                   let startTime = viewModel.roomStartTime {
                    CurrentRoomCard(
                        room: currentRoom,
                        startTime: startTime,
                        onLeave: {
                            viewModel.leaveCurrentRoom()
                        }
                    )
                    .padding()
                }
                
                // 部屋一覧
                List(filteredRooms) { room in
                    RoomRowView(
                        room: room,
                        isCurrentRoom: viewModel.currentRoom?.id == room.id,
                        onJoin: {
                            viewModel.joinRoom(room)
                        },
                        viewModel: viewModel
                    )
                }
                .searchable(text: $searchText, prompt: "部屋名やタグで検索")
            }
            .navigationTitle("努力の部屋")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateRoom = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoom) {
                CreateRoomView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - 現在の部屋カード
struct CurrentRoomCard: View {
    let room: Room
    let startTime: Date
    let onLeave: () -> Void
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("現在の部屋")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(room.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button("退出", role: .destructive) {
                    onLeave()
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("経過時間: \(formatTime(elapsedTime))")
                    .font(.headline)
                
                Spacer()
                
                // 参加者アイコン表示
                VStack(alignment: .trailing, spacing: 4) {
                    Text("参加者")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ParticipantsIconRow(participants: room.participants)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - 参加者アイコン行
struct ParticipantsIconRow: View {
    let participants: [User]
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(participants.prefix(5).enumerated()), id: \.element.id) { index, participant in
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: participant.profileImage ?? "person.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .zIndex(Double(participants.count - index))
            }
            
            if participants.count > 5 {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text("+\(participants.count - 5)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            }
        }
    }
}

// MARK: - 部屋行ビュー
struct RoomRowView: View {
    let room: Room
    let isCurrentRoom: Bool
    let onJoin: () -> Void
    @State private var showingChat = false
    @State private var showingPasswordAlert = false
    @State private var password = ""
    @State private var showingJoinError = false
    @State private var joinErrorMessage = ""
    @State private var showingCloseRoomAlert = false
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(room.name)
                    .font(.headline)
                    .foregroundColor(room.isClosed ? .secondary : .primary)
                
                // 部屋が閉鎖されている場合の表示
                if room.isClosed {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("閉鎖済み")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        if let closedAt = room.closedAt {
                            Text("(\(closedAt, style: .relative))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                // タグ表示
                HStack {
                    ForEach(room.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    // プライベート設定の表示
                    if room.isPrivate {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    if room.isInviteOnly {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    
                    // 部屋の閉鎖状態表示
                    if room.isClosed {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer() // This Spacer was moved from the end of the HStack to allow icons to be next to tags
                    
                    Text(room.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 参加者アイコン表示
                if !room.participants.isEmpty {
                    ParticipantsIconRow(participants: room.participants)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                if isCurrentRoom {
                    Text("参加中")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    
                    // チャットボタン
                    Button(action: {
                        showingChat = true
                    }) {
                        Image(systemName: "message.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    
                    // 部屋作成者のみ閉鎖ボタンを表示
                    if room.isCreator(userId: viewModel.currentUser?.id ?? UUID()) {
                        Button(action: {
                            showingCloseRoomAlert = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                } else if !room.isClosed {
                    Button("参加") {
                        if room.isPrivate && room.password != nil {
                            showingPasswordAlert = true
                        } else {
                            attemptJoin()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("閉鎖済み")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingChat) {
            NavigationView {
                ChatView(viewModel: AppViewModel(), room: room)
            }
        }
        .alert("パスワード入力", isPresented: $showingPasswordAlert) {
            SecureField("パスワード", text: $password)
            Button("参加") {
                attemptJoin()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この部屋に参加するにはパスワードが必要です")
        }
        .alert("参加エラー", isPresented: $showingJoinError) {
            Button("OK") { }
        } message: {
            Text(joinErrorMessage)
        }
        .alert("部屋を閉鎖", isPresented: $showingCloseRoomAlert) {
            Button("閉鎖", role: .destructive) {
                viewModel.closeRoom(roomId: room.id)
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この部屋を閉鎖しますか？\n\n閉鎖すると、すべての参加者が退出し、部屋に参加できなくなります。この操作は取り消せません。")
        }
    }
    
    private func attemptJoin() {
        // ここでAppViewModelのjoinRoomメソッドを呼び出す必要があります
        // 現在の実装ではonJoinクロージャーを使用しているため、
        // パスワード検証を含む新しい実装が必要です
        onJoin()
    }
}

#Preview {
    RoomListView(viewModel: AppViewModel())
} 