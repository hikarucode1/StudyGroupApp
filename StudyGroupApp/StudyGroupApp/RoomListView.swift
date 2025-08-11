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
                        }
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
                
                Text("参加者: \(room.participants.count)人")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // タグ表示
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(room.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
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

// MARK: - 部屋行ビュー
struct RoomRowView: View {
    let room: Room
    let isCurrentRoom: Bool
    let onJoin: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(room.name)
                    .font(.headline)
                
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
                }
                
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.secondary)
                    Text("\(room.participants.count)人参加中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(room.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isCurrentRoom {
                Text("参加中")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else {
                Button("参加") {
                    onJoin()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RoomListView(viewModel: AppViewModel())
} 